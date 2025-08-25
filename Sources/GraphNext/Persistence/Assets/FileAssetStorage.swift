//
//  FileAssetStorage.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/25.
//

import Foundation
import CryptoKit

/// Implementazione file‑backed:
/// - contenuto content-addressed: `content/<aa>/<bb>/<sha256>`
/// - indice per assetId:       `index/<assetId>.json`  -> { sha256, length, mimeType, fileName, lastAccess }
///
/// Vantaggi:
/// - dedup automatico per sha256
/// - open/url/exists risolti via indice assetId -> sha256
/// - pronto per futura eviction LRU (usa lastAccess)
public final class FileAssetStorage: AssetStorage {

    // MARK: Types

    private struct IndexRecord: Codable {
        var sha256: String
        var length: Int
        var mimeType: String
        var fileName: String?
        var lastAccess: Date
    }

    // MARK: Paths

    public let baseDirectory: URL
    private let indexDir: URL
    private let contentDir: URL
    private let ioQueue = DispatchQueue(label: "FileAssetStorage.ioQueue", qos: .utility)

    /// Quota cache (byte). Quando superata, scatta eviction LRU (best-effort). 0 = disattivata.
    public let quotaBytes: Int

    // MARK: Init

    /// - Parameters:
    ///   - baseDirectory: directory radice (es. Application Support / GraphNextAssets).
    ///                    Se non esiste verrà creata.
    public init(baseDirectory: URL, quotaBytes: Int = 200 * 1024 * 1024) throws {
        self.baseDirectory = baseDirectory
        self.indexDir = baseDirectory.appendingPathComponent("index", isDirectory: true)
        self.contentDir = baseDirectory.appendingPathComponent("content", isDirectory: true)
        self.quotaBytes = max(0, quotaBytes)

        try FileManager.default.createDirectory(at: indexDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: contentDir, withIntermediateDirectories: true)
    }

    /// Comodo factory che posiziona la directory in Application Support.
    public static func makeDefaultBaseDirectory() throws -> URL {
        #if os(iOS) || os(tvOS) || os(watchOS)
        let root = try FileManager.default.url(for: .applicationSupportDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil, create: true)
        #else
        let root = try FileManager.default.url(for: .applicationSupportDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil, create: true)
        #endif
        return root.appendingPathComponent("GraphNextAssets", isDirectory: true)
    }

    // MARK: AssetStorage

    public func save(data: Data, for assetId: UUID, meta: AssetMetadata) throws -> URL {
        let computed = data.sha256Hex()
        guard computed == meta.sha256 else {
            throw AssetStorageError.checksumMismatch
        }

        return try performSync {
            // 1) Scrivi contenuto (se non già presente)
            let contentURL = self.contentURL(forSHA: meta.sha256)
            if !FileManager.default.fileExists(atPath: contentURL.path) {
                // Scrittura atomica
                let tmp = contentURL.appendingPathExtension("tmp-\(UUID().uuidString)")
                do {
                    try data.write(to: tmp, options: .atomic)
                    try FileManager.default.moveItem(at: tmp, to: contentURL)
                } catch {
                    // cleanup temporaneo, se esiste
                    try? FileManager.default.removeItem(at: tmp)
                    throw AssetStorageError.ioError(underlying: error)
                }
            }

            // 2) Aggiorna/crea indice assetId -> sha256
            let record = IndexRecord(
                sha256: meta.sha256,
                length: meta.length,
                mimeType: meta.mimeType,
                fileName: meta.fileName,
                lastAccess: Date()
            )
            try self.writeIndex(record, for: assetId)
            try self.enforceQuotaIfNeeded()
            return contentURL
        }
    }

    public func openRead(assetId: UUID) throws -> InputStream? {
        try performSync {
            guard var rec = try self.readIndex(for: assetId) else { return nil }
            let contentURL = self.contentURL(forSHA: rec.sha256)
            guard FileManager.default.fileExists(atPath: contentURL.path) else { return nil }

            // Aggiorna lastAccess
            rec.lastAccess = Date()
            try self.writeIndex(rec, for: assetId)
            return InputStream(url: contentURL)
        }
    }

    public func urlIfPresent(assetId: UUID) throws -> URL? {
        try performSync {
            guard var rec = try self.readIndex(for: assetId) else { return nil }
            let contentURL = self.contentURL(forSHA: rec.sha256)
            guard FileManager.default.fileExists(atPath: contentURL.path) else {
                // file mancante: indice stale → pulizia
                try? self.deleteIndex(for: assetId)
                return nil
            }
            // touch LRU
            rec.lastAccess = Date()
            try self.writeIndex(rec, for: assetId)
            return contentURL
        }
    }

    public func exists(assetId: UUID) throws -> Bool {
        try performSync {
            guard let rec = try self.readIndex(for: assetId) else { return false }
            let contentURL = self.contentURL(forSHA: rec.sha256)
            return FileManager.default.fileExists(atPath: contentURL.path)
        }
    }

    public func remove(assetId: UUID) throws {
        try performSync {
            guard let rec = try self.readIndex(for: assetId) else { return }
            // 1) Rimuovi indice
            try self.deleteIndex(for: assetId)
            // 2) Se nessun altro indice punta allo stesso SHA, rimuovi il contenuto
            if try !self.anyIndexPoints(toSHA: rec.sha256) {
                let url = self.contentURL(forSHA: rec.sha256)
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    public func verifyChecksum(assetId: UUID) throws -> Bool {
        try performSync {
            guard let rec = try self.readIndex(for: assetId) else { return false }
            let url = self.contentURL(forSHA: rec.sha256)
            guard let stream = InputStream(url: url) else { return false }
            stream.open()
            defer { stream.close() }

            var hasher = CryptoKit.SHA256()
            let chunkSize = 256 * 1024
            var buffer = [UInt8](repeating: 0, count: chunkSize)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: chunkSize)
                if read < 0 { return false }
                if read == 0 { break }
                hasher.update(data: Data(buffer[0..<read]))
            }
            let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
            return digest == rec.sha256
        }
    }

    // MARK: Private helpers

    private func performSync<T>(_ block: () throws -> T) rethrows -> T {
        try ioQueue.sync(execute: block)
    }

    private func contentURL(forSHA sha: String) -> URL {
        let a = String(sha.prefix(2))
        let b = String(sha.dropFirst(2).prefix(2))
        let dir = contentDir.appendingPathComponent(a, isDirectory: true)
                             .appendingPathComponent(b, isDirectory: true)
        // crea directory se necessario
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(sha, isDirectory: false)
    }

    private func indexURL(for assetId: UUID) -> URL {
        indexDir.appendingPathComponent(assetId.uuidString + ".json", isDirectory: false)
    }

    private func readIndex(for assetId: UUID) throws -> IndexRecord? {
        let url = indexURL(for: assetId)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(IndexRecord.self, from: data)
        } catch {
            throw AssetStorageError.ioError(underlying: error)
        }
    }

    private func writeIndex(_ rec: IndexRecord, for assetId: UUID) throws {
        let url = indexURL(for: assetId)
        do {
            let data = try JSONEncoder().encode(rec)
            try data.write(to: url, options: .atomic)
        } catch {
            throw AssetStorageError.ioError(underlying: error)
        }
    }

    private func deleteIndex(for assetId: UUID) throws {
        let url = indexURL(for: assetId)
        if FileManager.default.fileExists(atPath: url.path) {
            do { try FileManager.default.removeItem(at: url) }
            catch { throw AssetStorageError.ioError(underlying: error) }
        }
    }

    private func anyIndexPoints(toSHA sha: String) throws -> Bool {
        // Scansione veloce dell'intera cartella index; ok perché i record sono piccoli.
        // (Ottimizzabile in futuro con una tabella di riferimento/contatore).
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: indexDir, includingPropertiesForKeys: nil) else {
            return false
        }
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let rec = try? JSONDecoder().decode(IndexRecord.self, from: data),
               rec.sha256 == sha {
                return true
            }
        }
        return false
    }

    // MARK: - LRU / Eviction

    /// Restituisce tutti gli index record (assetId -> record).
    private func readAllIndexRecords() -> [(UUID, IndexRecord)] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: indexDir, includingPropertiesForKeys: nil) else {
            return []
        }
        var result: [(UUID, IndexRecord)] = []
        for url in files where url.pathExtension == "json" {
            let name = url.deletingPathExtension().lastPathComponent
            guard let id = UUID(uuidString: name) else { continue }
            if let data = try? Data(contentsOf: url),
               let rec = try? JSONDecoder().decode(IndexRecord.self, from: data) {
                result.append((id, rec))
            }
        }
        return result
    }

    /// Calcola la dimensione totale dichiarata dagli index record.
    private func totalSizeBytes() -> Int {
        readAllIndexRecords().reduce(0) { $0 + $1.1.length }
    }

    /// Mappa sha256 -> numero di riferimenti negli index record.
    private func shaRefCounts() -> [String: Int] {
        var counts: [String: Int] = [:]
        for (_, rec) in readAllIndexRecords() {
            counts[rec.sha256, default: 0] += 1
        }
        return counts
    }

    /// Se la quota è superata, rimuove file partendo dai meno recenti (LRU) finché size <= quota.
    private func enforceQuotaIfNeeded() throws {
        guard quotaBytes > 0 else { return }
        var currentSize = totalSizeBytes()
        guard currentSize > quotaBytes else { return }

        // Ordina per lastAccess crescente (più vecchi prima)
        var all = readAllIndexRecords().sorted { $0.1.lastAccess < $1.1.lastAccess }
        var ref = shaRefCounts()

        while currentSize > quotaBytes, let victim = all.first {
            let (assetId, rec) = victim
            // Elimina index del victim
            try? self.deleteIndex(for: assetId)
            currentSize -= rec.length

            // Se questo sha non è più referenziato, rimuovi il contenuto
            if let c = ref[rec.sha256] {
                let newC = c - 1
                if newC <= 0 {
                    let url = self.contentURL(forSHA: rec.sha256)
                    try? FileManager.default.removeItem(at: url)
                    ref[rec.sha256] = nil
                } else {
                    ref[rec.sha256] = newC
                }
            }

            // Rimuovi l'elemento dalla lista e continua
            all.removeFirst()
        }
    }
}

//
//  LRUAssetIndex.swift
//  GraphNext
//
//  Created by Valerio Buriani on 25/08/25.
//

import Foundation

/// Info tracciate per ogni asset nel catalogo cache.
struct AssetCatalogEntry: Codable {
    let assetId: UUID
    var length: Int
    var sha256: String
    var mimeType: String?
    var fileName: String?
    /// Ultimo accesso (epoch seconds) per LRU
    var lastAccess: TimeInterval
}

/// Indice LRU minimale, persistito su disco (JSON).
/// Tiene traccia di `sizeBytes` totale e rimuove dal più vecchio in poi quando serve.
final class LRUAssetIndex {
    private var entries: [UUID: AssetCatalogEntry] = [:]
    private(set) var sizeBytes: Int = 0

    private let indexURL: URL
    private let ioQueue = DispatchQueue(label: "LRUAssetIndex.io")

    init(indexURL: URL) {
        self.indexURL = indexURL
        loadFromDiskIfPresent()
    }

    // MARK: - Public mutations (thread-safe tramite ioQueue)

    func upsert(assetId: UUID, meta: AssetMetadata, lastAccess: Date = .init()) {
        ioQueue.sync {
            if let old = entries[assetId] {
                // Adjust size if length changed
                sizeBytes += (meta.length - old.length)
                entries[assetId] = AssetCatalogEntry(
                    assetId: assetId,
                    length: meta.length,
                    sha256: meta.sha256,
                    mimeType: meta.mimeType,
                    fileName: meta.fileName,
                    lastAccess: lastAccess.timeIntervalSince1970
                )
            } else {
                sizeBytes += meta.length
                entries[assetId] = AssetCatalogEntry(
                    assetId: assetId,
                    length: meta.length,
                    sha256: meta.sha256,
                    mimeType: meta.mimeType,
                    fileName: meta.fileName,
                    lastAccess: lastAccess.timeIntervalSince1970
                )
            }
            persist()
        }
    }

    func markAccess(assetId: UUID, at date: Date = .init()) {
        ioQueue.sync {
            guard var e = entries[assetId] else { return }
            e.lastAccess = date.timeIntervalSince1970
            entries[assetId] = e
            persist()
        }
    }

    func remove(assetId: UUID) {
        ioQueue.sync {
            if let e = entries.removeValue(forKey: assetId) {
                sizeBytes -= e.length
                if sizeBytes < 0 { sizeBytes = 0 }
                persist()
            }
        }
    }

    /// Restituisce gli asset in ordine di ultimo accesso ASC (i più vecchi prima)
    func leastRecentlyUsedOrder() -> [AssetCatalogEntry] {
        ioQueue.sync {
            entries.values.sorted { $0.lastAccess < $1.lastAccess }
        }
    }

    func snapshot() -> [UUID: AssetCatalogEntry] {
        ioQueue.sync { entries }
    }

    // MARK: - Persistence

    private func loadFromDiskIfPresent() {
        ioQueue.sync {
            guard FileManager.default.fileExists(atPath: indexURL.path) else { return }
            do {
                let data = try Data(contentsOf: indexURL)
                let decoded = try JSONDecoder().decode([UUID: AssetCatalogEntry].self, from: data)
                self.entries = decoded
                self.sizeBytes = decoded.values.reduce(0) { $0 + $1.length }
            } catch {
                // Index corrotto: riparti da vuoto
                self.entries = [:]
                self.sizeBytes = 0
            }
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: indexURL, options: [.atomic])
        } catch {
            // Best-effort: non bloccare il flusso per errori sulla persistenza dell'indice
        }
    }
}

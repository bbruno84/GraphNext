//
//  AssetStorage.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/25.
//

import Foundation
import CryptoKit

/// Errori specifici per la gestione file‑backed degli asset.
public enum AssetStorageError: Error, LocalizedError {
    case indexNotFound(UUID)
    case contentNotFound(sha256: String)
    case checksumMismatch
    case ioError(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .indexNotFound(let id): return "Asset index not found for id \(id)"
        case .contentNotFound(let sha): return "Asset content not found for sha256 \(sha)"
        case .checksumMismatch: return "Computed checksum does not match expected sha256"
        case .ioError(let underlying): return "I/O error: \(underlying.localizedDescription)"
        }
    }
}

/// Interfaccia di storage per asset file‑backed.
/// N.B.: l’implementazione default è `FileAssetStorage`.
public protocol AssetStorage: Sendable {
    /// Salva i bytes su disco, indicizzando l’asset `assetId` verso il contenuto content-addressed `sha256`.
    /// Ritorna l’URL locale al file di contenuto (non all’indice).
    func save(data: Data, for assetId: UUID, meta: AssetMetadata) throws -> URL

    /// Stream in sola lettura per l’asset. Aggiorna il lastAccess nei metadati locali.
    func openRead(assetId: UUID) throws -> InputStream?

    /// URL locale del contenuto se presente (nil se mancante). Non scarica nulla.
    func urlIfPresent(assetId: UUID) throws -> URL?

    /// Verifica presenza di indice e contenuto locale.
    func exists(assetId: UUID) throws -> Bool

    /// Rimuove l’indice per `assetId`. Se nessun altro indice punta allo stesso `sha256`, rimuove anche il contenuto.
    func remove(assetId: UUID) throws

    /// Ricalcola lo SHA256 del contenuto locale puntato da `assetId` e lo confronta con quello atteso.
    func verifyChecksum(assetId: UUID) throws -> Bool
}

// MARK: - Utilities

extension Data {
    /// SHA256 in esadecimale (lowercase).
    public func sha256Hex() -> String {
        var hasher = SHA256()
        hasher.update(data: self)
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

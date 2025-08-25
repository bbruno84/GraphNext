//
//  CoreDataGraphPersistenceController+Assets.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/2025.
//

import Foundation

extension CoreDataGraphPersistenceController {

    // MARK: - File-backed Asset APIs (aligned with GRDB)

    /// Salva (o sovrascrive) i bytes dell'asset `assetId` nello storage file-backed e ritorna i metadati.
    @discardableResult
    public func saveAssetData(
        assetId: UUID,
        data: Data,
        mimeType: String,
        fileName: String? = nil
    ) async throws -> AssetMetadata {
        let sha = data.sha256Hex()
        let meta = AssetMetadata(length: data.count, sha256: sha, mimeType: mimeType, fileName: fileName)
        _ = try storage.save(data: data, for: assetId, meta: meta)
        return meta
    }

    /// Carica interamente i bytes dell'asset da storage file-backed.
    public func loadAssetData(assetId: UUID) async throws -> Data {
        guard let stream = try storage.openRead(assetId: assetId) else {
            throw NSError(domain: "GraphNext.CoreData", code: 404, userInfo: [NSLocalizedDescriptionKey: "Asset not found locally"])
        }
        stream.open()
        defer { stream.close() }
        var out = Data()
        var buf = [UInt8](repeating: 0, count: 256 * 1024)
        while stream.hasBytesAvailable {
            let n = stream.read(&buf, maxLength: buf.count)
            if n <= 0 { break }
            out.append(buf, count: n)
        }
        return out
    }

    /// Stream di sola lettura dal file locale (utile per CKAsset o copie su disco).
    public func openAssetStream(assetId: UUID) async throws -> InputStream? {
        try storage.openRead(assetId: assetId)
    }

    /// URL locale se presente (non forza download/sync).
    public func assetURLIfPresent(assetId: UUID) async throws -> URL? {
        try storage.urlIfPresent(assetId: assetId)
    }

    /// Rimuove l’asset dallo storage file-backed (non rimuove l’Entity).
    public func deleteAsset(assetId: UUID) async throws {
        try storage.remove(assetId: assetId)
    }

    /// Hook per plugin di sync (CloudKit) che scaricano on‑demand il file quando serve.
    /// Core Data: no‑op.
    public func fetchAssetIfNeeded(assetId: UUID) async throws { }

    // MARK: - Convenience: create + attach

    /// Crea un'Entity `asset`, salva i bytes su file storage, e collega con Relationship `attaches` al proprietario.
    public func createAssetAndAttach(
        data: Data,
        mimeType: String?,
        fileName: String?,
        attachTo ownerId: UUID
    ) async throws -> Entity {

        let mime = mimeType ?? "application/octet-stream"
        let sha = data.sha256Hex()
        let meta = AssetMetadata(length: data.count, sha256: sha, mimeType: mime, fileName: fileName)

        let assetId = UUID()
        let asset = Entity(
            id: assetId,
            type: "asset",
            tag: [],
            group: [],
            created: .init(by: "system", at: .now),
            updated: nil,
            version: 1,
            sharedWith: [],
            permissions: nil,
            payload: [
                "mimeType": .string(mime),
                "fileName": .string(fileName ?? ""),
                "length": .int(meta.length),
                "sha256": .string(meta.sha256)
            ]
        )

        let link = Relationship(
            id: UUID(),
            type: "attaches",
            tag: [],
            group: [],
            created: .init(by: "system", at: .now),
            updated: nil,
            version: 1,
            sharedWith: [],
            permissions: nil,
            payload: [:],
            from: ownerId,
            to: asset.id
        )

        // Persisti Entity + Relationship (Core Data) e salva file su storage
        try await saveEntity(asset)
        _ = try storage.save(data: data, for: assetId, meta: meta)
        try await saveRelationship(link)

        return asset
    }

    // MARK: - Private

    private var storage: AssetStorage { AssetStorageProvider.shared.storage }
}

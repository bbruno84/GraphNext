//
//  GRDBGraphPersistenceController+Assets.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//  Refactor file-backed by Regia GraphNext on 24/08/25
//

import Foundation
import CryptoKit
import GRDB

extension GRDBGraphPersistenceController {

    // MARK: - API pubbliche file-backed

    /// Salva (o sovrascrive) i bytes dell'asset `assetId` su storage file-backed e ritorna i metadati.
    /// Non tocca più il DB per i binari.
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
            throw NSError(domain: "GraphNext", code: 404, userInfo: [NSLocalizedDescriptionKey: "Asset not found locally"])
        }
        stream.open()
        defer { stream.close() }
        var out = Data()
        var buf = [UInt8](repeating: 0, count: 256*1024)
        while stream.hasBytesAvailable {
            let n = stream.read(&buf, maxLength: buf.count)
            if n < 0 { break }
            if n == 0 { break }
            out.append(buf, count: n)
        }
        return out
    }

    /// Stream di sola lettura dal file locale (comodo per CKAsset o copie su disco).
    public func openAssetStream(assetId: UUID) async throws -> InputStream? {
        try storage.openRead(assetId: assetId)
    }

    /// URL locale se presente (non forza download/sync).
    public func assetURLIfPresent(assetId: UUID) async throws -> URL? {
        try storage.urlIfPresent(assetId: assetId)
    }

    /// Rimuove l’asset dal file storage. Non rimuove l’Entity; per quello usa deleteEntity(_:)
    public func deleteAsset(assetId: UUID) async throws {
        try storage.remove(assetId: assetId)
    }

    /// Hook per plugin di sync (CloudKit) che scaricano on‑demand il file quando serve.
    /// Implementazione GRDB: no‑op, ritorna subito.
    public func fetchAssetIfNeeded(assetId: UUID) async throws {
        // no-op per GRDB: lo storage locale non scarica da remoto.
        // Il plugin CloudKit farà override/usando un service specifico.
    }

    // MARK: - Helper

    private var storage: AssetStorage {
        AssetStorageProvider.shared.storage
    }
}

// MARK: - Convenience: createAssetAndAttach (file-backed)

extension GRDBGraphPersistenceController {

    /// Crea un'Entity `asset`, salva i bytes su file storage, e collega con Relationship `attaches` al proprietario.
    public func createAssetAndAttach(
        data: Data,
        mimeType: String?,
        fileName: String?,
        attachTo ownerId: UUID
    ) async throws -> Entity {
        // 1. Calcolo metadati
        _ = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()

        // 1) Metadati e Entity asset
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

        // 2) Persisti Entity + Relationship (DB), e salva file su storage
        try await saveEntity(asset, allowAsset: true)
        _ = try storage.save(data: data, for: assetId, meta: meta)
        try await saveRelationship(link)

        return asset
    }
}

//
//  GRDBGraphPersistenceController+Assets.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//

import Foundation
import CryptoKit
import GRDB

extension GRDBGraphPersistenceController {

    public func saveAssetBlob(
        for assetId: UUID,
        data: Data,
        mimeType: String? = nil,
        fileName: String? = nil
    ) async throws -> AssetMetadata {
        try await dbQueue.write { db in
            let length = data.count
            let sha256 = Data(SHA256.hash(data: data)).base64EncodedString()

            try db.execute(sql: """
                INSERT OR REPLACE INTO asset_blobs (entityId, data, length, sha256, mimeType, fileName)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    assetId.uuidString,
                    data,
                    length,
                    sha256,
                    mimeType,
                    fileName
                ])

            return AssetMetadata(length: length, sha256: sha256, mimeType: mimeType, fileName: fileName)
        }
    }
}

extension GRDBGraphPersistenceController {

    public func loadAssetBlob(for assetId: UUID) async throws -> (data: Data, meta: AssetMetadata) {
        try await dbQueue.read { db in
            guard let row = try Row.fetchOne(
                db,
                sql: """
                    SELECT data, length, sha256, mimeType, fileName
                    FROM asset_blobs
                    WHERE entityId = ?
                    """,
                arguments: [assetId.uuidString]
            ) else {
                throw NSError(domain: "GraphNext", code: 404, userInfo: [NSLocalizedDescriptionKey: "Asset not found"])
            }

            guard let data: Data = row["data"] else {
                throw NSError(domain: "GraphNext", code: 500, userInfo: [NSLocalizedDescriptionKey: "Asset data corrupted"])
            }

            let length: Int = row["length"]
            let sha256: String = row["sha256"]
            let mimeType: String? = row["mimeType"]
            let fileName: String? = row["fileName"]

            return (
                data,
                AssetMetadata(length: length, sha256: sha256, mimeType: mimeType, fileName: fileName)
            )
        }
    }
}

extension GRDBGraphPersistenceController {

    public func deleteAssetBlob(for assetId: UUID) async throws {
        try await dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM asset_blobs WHERE entityId = ?",
                arguments: [assetId.uuidString]
            )
        }
    }
}

extension GRDBGraphPersistenceController {
    public func createAssetAndAttach(
        data: Data,
        mimeType: String?,
        fileName: String?,
        attachTo ownerId: UUID
    ) async throws -> Entity {
        // 1. Calcolo metadati
        let sha256 = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        let meta = AssetMetadata(
            length: data.count,
            sha256: sha256,
            mimeType: mimeType,
            fileName: fileName
        )

        // 2. Crea Entity asset
        let asset = Entity(
            id: UUID(),
            type: "asset",
            tag: [],
            group: [],
            created: .init(by: "system", at: .now),
            updated: nil,
            version: 1,
            sharedWith: [],
            permissions: nil,
            payload: [
                "mimeType": .string(mimeType ?? ""),
                "fileName": .string(fileName ?? ""),
                "length": .int(data.count),
                "sha256": .string(sha256)
            ]
        )

        // 3. Crea Relationship
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

        // 4. Salva tutto
        try await saveEntity(asset)
        _ = try await saveAssetBlob(for: asset.id, data: data, mimeType: mimeType, fileName: fileName)
        try await saveRelationship(link)

        return asset
    }
}

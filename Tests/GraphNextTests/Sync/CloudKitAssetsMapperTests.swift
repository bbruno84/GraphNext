//
//  CloudKitAssetsMapperTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/25.
//


import XCTest
import CloudKit
@testable import GraphNext

final class CloudKitAssetsMapperTests: XCTestCase {

    override func setUpWithError() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("GN_Assets_CKMapper_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        AssetStorageProvider.shared.setStorage(try FileAssetStorage(baseDirectory: dir))
    }

    func testAsCKRecord_AttachesCKAssetIfLocalURLExists() throws {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let sha = data.sha256Hex()
        let assetId = UUID()
        let meta = AssetMetadata(length: data.count, sha256: sha, mimeType: "application/octet-stream", fileName: "deadbeef.bin")
        _ = try AssetStorageProvider.shared.storage.save(data: data, for: assetId, meta: meta)

        let entity = Entity(
            id: assetId,
            type: "asset",
            tag: [],
            group: [],
            created: .init(by: "test", at: .now),
            updated: nil,
            version: 1,
            sharedWith: [],
            permissions: nil,
            payload: [
                "mimeType": .string("application/octet-stream"),
                "fileName": .string("deadbeef.bin"),
                "length": .int(data.count),
                "sha256": .string(sha)
            ]
        )

        let record = entity.asCKRecord()
        
        let ckAsset = record["file"] as? CKAsset
        XCTAssertNotNil(ckAsset)
        XCTAssertNotNil(ckAsset?.fileURL)
    }
}

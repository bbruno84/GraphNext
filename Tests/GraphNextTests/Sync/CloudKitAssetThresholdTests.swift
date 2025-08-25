//
//  CloudKitAssetThresholdTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 25/08/25.
//


import XCTest
import CloudKit
@testable import GraphNext

final class CloudKitAssetThresholdTests: XCTestCase {

    override func setUpWithError() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("GN_Assets_Threshold_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        AssetStorageProvider.shared.setStorage(try FileAssetStorage(baseDirectory: dir))
    }

    func testAsCKRecord_SkipsAttachmentWhenOverThreshold() throws {
        // Soglia 4 byte
        _CKAttachmentThreshold.bytes = 4

        // 5 byte → sopra soglia
        let data = Data("12345".utf8)
        let assetId = UUID()
        let meta = AssetMetadata(length: data.count,
                                 sha256: data.sha256Hex(),
                                 mimeType: "text/plain",
                                 fileName: "big.txt")
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
                "mimeType": .string("text/plain"),
                "fileName": .string("big.txt"),
                "length": .int(data.count),
                "sha256": .string(meta.sha256)
            ]
        )

        let record = entity.asCKRecord()
        XCTAssertNil(record["file"] as? CKAsset, "CKAsset should be skipped when size > threshold")
    }

    func testAsCKRecord_AttachesWhenUnderThreshold() throws {
        // Soglia 10 byte
        _CKAttachmentThreshold.bytes = 10

        let data = Data("1234".utf8) // 4 byte < 10
        let assetId = UUID()
        let meta = AssetMetadata(length: data.count,
                                 sha256: data.sha256Hex(),
                                 mimeType: "text/plain",
                                 fileName: "small.txt")
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
                "mimeType": .string("text/plain"),
                "fileName": .string("small.txt"),
                "length": .int(data.count),
                "sha256": .string(meta.sha256)
            ]
        )

        let record = entity.asCKRecord()
        XCTAssertNotNil(record["file"] as? CKAsset, "CKAsset should be attached when size <= threshold")
    }
}

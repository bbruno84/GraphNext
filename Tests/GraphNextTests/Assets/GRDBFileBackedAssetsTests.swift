//
//  GRDBFileBackedAssetsTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/25.
//


//
//  GRDBFileBackedAssetsTests.swift
//  GraphNextTests
//
//  Created by Regia GraphNext on 24/08/2025.
//

import XCTest
@testable import GraphNext

final class GRDBFileBackedAssetsTests: XCTestCase {

    private func makeController() throws -> GRDBGraphPersistenceController {
        // Se hai un helper, usa quello. Qui esempio rapido con path temp:
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("GN_GRDB_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let dbURL = dir.appendingPathComponent("graph.sqlite")
        let controller = try GRDBGraphPersistenceController(path: dbURL.path, inMemory: false)
        return controller
    }

    func testCreateAttachAndRoundTrip() async throws {
        // AssetStorage default punta ad Application Support; qui lo forziamo a temp per isolare il test
        let assetsDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("GN_Assets_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        try AssetStorageProvider.shared.setStorage(FileAssetStorage(baseDirectory: assetsDir))

        let controller = try makeController()

        // Owner entity
        let owner = Entity(
            id: UUID(),
            type: "doc",
            tag: [],
            group: [],
            created: .init(by: "test", at: .now),
            updated: nil,
            version: 1,
            sharedWith: [],
            permissions: nil,
            payload: [:]
        )
        try await controller.saveEntity(owner)

        // Data fake
        let data = Data([0x25, 0x50, 0x44, 0x46]) // "%PDF" header-like bytes
        let asset = try await controller.createAssetAndAttach(
            data: data,
            mimeType: "application/pdf",
            fileName: "sample.pdf",
            attachTo: owner.id
        )

        // URL presente?
        let url = try await controller.assetURLIfPresent(assetId: asset.id)
        XCTAssertNotNil(url)

        // Load bytes e verifica sha
        let loaded = try await controller.loadAssetData(assetId: asset.id)
        XCTAssertEqual(loaded, data)

        // Verify checksum
        let ok = try AssetStorageProvider.shared.storage.verifyChecksum(assetId: asset.id)
        XCTAssertTrue(ok)

        // Delete asset file (non entity)
        try await controller.deleteAsset(assetId: asset.id)
        let urlAfterDelete = try await controller.assetURLIfPresent(assetId: asset.id)
        XCTAssertNil(urlAfterDelete)
    }
}

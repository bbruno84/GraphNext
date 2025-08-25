//
//  GRDBGraphPersistenceController.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//


import XCTest
@testable import GraphNext

final class GRDBGraphPersistenceController_AssetsTests: XCTestCase {

    var sut: GRDBGraphPersistenceController!

    override class func setUp() {
        // Optional: any one-time setup logic
    }

    override func setUp() async throws {
        sut = try GRDBGraphPersistenceController(path: "TestAssets", inMemory: true)
        try await Task.sleep(nanoseconds: 100_000_000) // Give GRDB time to migrate
    }

    func testAssetRoundTrip_FileBacked() async throws {
        let data = Data("hello world".utf8)
        let mimeType = "text/plain"
        let fileName = "test.txt"

        let asset = try await sut.createAssetAndAttach(
            data: data,
            mimeType: mimeType,
            fileName: fileName,
            attachTo: UUID()
        )

        let loadedData = try await sut.loadAssetData(assetId: asset.id)

        XCTAssertEqual(loadedData, data)
        // Validate metadata via entity payload (file-backed: no direct blob metadata API)
        let fetchedAsset = try await sut.entity(id: asset.id)
        XCTAssertNotNil(fetchedAsset)
        guard let payload = fetchedAsset!.payload else { XCTFail("Missing payload in asset entity"); return }
        // length
        if case let .int(len)? = payload["length"] { XCTAssertEqual(len, data.count) } else { XCTFail("Missing length in payload") }
        // mimeType
        if case let .string(mt)? = payload["mimeType"] { XCTAssertEqual(mt, mimeType) } else { XCTFail("Missing mimeType in payload") }
        // fileName
        if case let .string(fn)? = payload["fileName"] { XCTAssertEqual(fn, fileName) } else { XCTFail("Missing fileName in payload") }
        // sha256
        if case let .string(sha)? = payload["sha256"] { XCTAssertEqual(sha, data.sha256Hex()) } else { XCTFail("Missing sha256 in payload") }
    }

    func testCascadeDeleteAssetAlsoRemovesFile() async throws {
        let data = Data("to be deleted".utf8)

        let asset = try await sut.createAssetAndAttach(
            data: data,
            mimeType: "text/plain",
            fileName: "delete.txt",
            attachTo: UUID()
        )

        try await sut.deleteEntity(id: asset.id)

        // Verifica che il file locale sia stato rimosso (nessun URL presente)
        let urlAfterDelete = try AssetStorageProvider.shared.storage.urlIfPresent(assetId: asset.id)
        XCTAssertNil(urlAfterDelete, "Expected asset file to be removed from local storage")

        // E continua a verificare che il caricamento fallisca
        do {
            _ = try await sut.loadAssetData(assetId: asset.id)
            XCTFail("Expected error when loading deleted asset blob")
        } catch {
            // Expected
        }
    }

    func testOwnerEntityAttachesAsset() async throws {
        let owner = Entity(
            id: UUID(),
            type: "invoice",
            tag: [],
            group: [],
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            sharedWith: [],
            permissions: nil,
            payload: [:]
        )

        try await sut.saveEntity(owner)

        let asset = try await sut.createAssetAndAttach(
            data: Data("attached".utf8),
            mimeType: "text/plain",
            fileName: "attached.txt",
            attachTo: owner.id
        )

        let allRelationships = try await sut.allRelationships()
        let attaches = allRelationships.first(where: { $0.type == "attaches" && $0.from == owner.id && $0.to == asset.id })

        XCTAssertNotNil(attaches, "Expected an 'attaches' relationship from owner to asset")
    }
    
    func testRelatedEntitiesIncludeAttachedAsset() async throws {
        let owner = Entity(
            id: UUID(),
            type: "invoice",
            tag: [],
            group: [],
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            sharedWith: [],
            permissions: nil,
            payload: [:]
        )

        try await sut.saveEntity(owner)

        let asset = try await sut.createAssetAndAttach(
            data: Data("linked".utf8),
            mimeType: "text/plain",
            fileName: "linked.txt",
            attachTo: owner.id
        )

        let related = try await sut.relatedEntities(from: owner.id)

        XCTAssertTrue(related.contains(where: { $0.id == asset.id }), "Expected attached asset to be in relatedEntities")
    }
}

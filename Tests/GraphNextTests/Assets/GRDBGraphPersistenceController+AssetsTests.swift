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

    func testAssetBlobRoundTrip() async throws {
        let data = Data("hello world".utf8)
        let mimeType = "text/plain"
        let fileName = "test.txt"

        let asset = try await sut.createAssetAndAttach(
            data: data,
            mimeType: mimeType,
            fileName: fileName,
            attachTo: UUID()
        )

        let (loadedData, metadata) = try await sut.loadAssetBlob(for: asset.id)

        XCTAssertEqual(loadedData, data)
        XCTAssertEqual(metadata.length, data.count)
        XCTAssertEqual(metadata.mimeType, mimeType)
        XCTAssertEqual(metadata.fileName, fileName)
    }

    func testCascadeDeleteAssetAlsoDeletesBlob() async throws {
        let data = Data("to be deleted".utf8)

        let asset = try await sut.createAssetAndAttach(
            data: data,
            mimeType: "text/plain",
            fileName: "delete.txt",
            attachTo: UUID()
        )

        try await sut.deleteEntity(id: asset.id)

        // Verifica che la riga nella tabella asset_blobs sia stata eliminata
        try await sut.dbQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM asset_blobs WHERE entityId = ?", arguments: [asset.id.uuidString])
            XCTAssertEqual(count, 0, "Expected asset blob to be deleted via cascade")
        }

        // E continua a verificare che il caricamento fallisca
        do {
            _ = try await sut.loadAssetBlob(for: asset.id)
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

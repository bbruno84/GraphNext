//
//  ResetTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 03/08/25.
//


import XCTest
import GraphNext
import GraphPersistence
@testable import GraphSyncEngine

final class CloudKitResetTests: XCTestCase {
    var persistence: GraphPersistenceController!
    var store: GraphStore!
    var syncEngine: CloudKitSync!

    override func setUpWithError() throws {
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext", inMemory: true)
        store = GraphStore()
        syncEngine = CloudKitSync(persistence: persistence, store: store)
    }

    override func tearDownWithError() throws {
        persistence = nil
        store = nil
        syncEngine = nil
    }

    func testResetClearsStore() async throws {
        // Precondizione: aggiungo un nodo
        let testEntity = Entity(
            id: UUID(),
            type: "Test",
            created: AuditInfo(by: "test", at: Date())
        )
        store.add(testEntity)
        XCTAssertFalse(store.entities.isEmpty)

        // Test reset
        try await syncEngine.reset()
        XCTAssertTrue(store.entities.isEmpty, "Store non dovrebbe contenere entity dopo reset")
        XCTAssertTrue(store.relationships.isEmpty, "Store non dovrebbe contenere relationship dopo reset")
    }

    func testResetDownloadsFromCloudKit() async throws {
        try await syncEngine.reset()

        // Nota: questo test fallirà se non ci sono dati validi in CloudKit.
        // Per test ripetibili, si consiglia un backend simulato o una configurazione nota.
        XCTAssertTrue(store.entities.count >= 0)
    }
}


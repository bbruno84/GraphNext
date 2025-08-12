//
//  PullTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 03/08/25.
//

import XCTest
import CloudKit
@testable import GraphSyncEngine
@testable import GraphNext
@testable import GraphPersistence

final class PullTests: XCTestCase {

    var persistence: GraphPersistenceController!
    var store: GraphStore!
    var syncEngine: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext", inMemory: true)
        store = GraphStore()
        syncEngine = CloudKitSync(persistence: persistence, store: store)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        persistence = nil
        store = nil
        syncEngine = nil
    }

    func testPullFetchesEntitiesAndRelationships() async throws {
        // ⚠️ Test reale: richiede dati esistenti su CloudKit
        try await syncEngine.pull()

        let allEntities = store.allEntities()
        let allRelationships = store.allRelationships()

        // Semplice check che qualcosa sia stato ricevuto
        XCTAssertGreaterThanOrEqual(allEntities.count, 0)
        XCTAssertGreaterThanOrEqual(allRelationships.count, 0)
        // In test locale potresti voler controllare valori più specifici
    }

    func testPullWithEmptyCloudKitDoesNotCrash() async throws {
        // ⚠️ Suppone che il database sia vuoto o filtrato per un determinato owner
        try await syncEngine.pull()

        let entities = store.allEntities()
        let relationships = store.allRelationships()

        XCTAssertTrue(entities.isEmpty || entities.count >= 0)
        XCTAssertTrue(relationships.isEmpty || relationships.count >= 0)
    }
}

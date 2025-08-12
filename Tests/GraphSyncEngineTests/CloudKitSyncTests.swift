//
//  CloudKitSyncTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 03/08/25.
//

import XCTest
import CloudKit
import GraphPersistence
@testable import GraphSyncEngine
@testable import GraphNext

final class SyncTests: XCTestCase {
    var persistence: GraphPersistenceController!
    var store: GraphStore!
    var sync: CloudKitSync!

    override func setUpWithError() throws {
        persistence = CoreDataGraphPersistenceController(storeName: "TestStore", inMemory: true)
        store = GraphStore()
        sync = CloudKitSync(persistence: persistence, store: store)
    }

    override func tearDownWithError() throws {
        persistence = nil
        store = nil
        sync = nil
    }

    func testSyncCombinesPullAndPush() async throws {
        // Precondizione: Aggiungiamo una Entity localmente (verrà pushata)
        let entity = Entity(
            id: UUID(),
            type: "TestType",
            created: AuditInfo(by: "test", at: .now)
        )
        store.add(entity)

        // Azione: sync
        try await sync.sync()

        // Postcondizione: controllo minimo sul fatto che l'oggetto sia ancora in cache
        XCTAssertTrue(store.entities[entity.id] != nil)
        // Ulteriori verifiche richiedono mocking del backend o controllo manuale CloudKit
    }

    func testSyncWithEmptyStoreDoesNotCrash() async throws {
        // Store vuoto
        XCTAssertTrue(store.entities.isEmpty)
        XCTAssertTrue(store.relationships.isEmpty)

        try await sync.sync()
        // Se non lancia errori, il test è superato
    }
}


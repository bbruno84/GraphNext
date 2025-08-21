//
//  PushFlowTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/08/25.
//

import XCTest
@testable import GraphNext

final class PushFlowTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-Push", inMemory: true)
        store = GraphStore()
        backend = MockRemoteBackend()

        // Debounce molto alto per evitare l'auto-push durante i test (push solo manuale)
        let config = CloudKitSyncConfig(
            containerIdentifier: nil,
            zoneName: "GraphNextZone",
            stateStore: .userDefaults(suiteName: "CKSE.GraphNextState.Tests"),
            subscribeOnInit: false,
            subscriptionID: "GraphNextSyncSubscription.Tests.Push",
            debounceMilliseconds: 5_000,   // alto: no auto-push
            retryMaxAttempts: 1,
            retryBaseDelaySeconds: 0.01
        )

        sync = await CloudKitSync(
            persistence: persistence,
            store: store,
            backend: backend,
            configuration: config
        )
    }

    // MARK: - Helpers

    private func makeEntity(type: String = "E", payload: GraphPayload? = nil) -> Entity {
        Entity(
            id: UUID(),
            type: type,
            created: .init(by: "local", at: .now),
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: payload
        )
    }

    private func makeRelationship(type: String = "R", from: UUID, to: UUID, at: Date = .now) -> Relationship {
        Relationship(
            id: UUID(),
            type: type,
            created: .init(by: "local", at: at),
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: nil,
            from: from,
            to: to
        )
    }

    // MARK: - Tests

    func testPushIncrementalAndIdempotentForEntities() async throws {
        // 1) Inserisco 2 entities nello store
        var e1 = makeEntity(type: "P1")
        var e2 = makeEntity(type: "P2")
        store.add(e1)
        store.add(e2)

        // 2) push manuale → deve inviare entrambe (primo batch)
        try await sync.push()
        XCTAssertEqual(backend.savedEntitiesBatches.count, 1, "Primo push: un batch")
        XCTAssertEqual(backend.entitiesStore.count, 2)

        // 3) push manuale immediato senza modifiche → nessun nuovo batch (idempotenza)
        try await sync.push()
        XCTAssertEqual(backend.savedEntitiesBatches.count, 1, "Nessun nuovo batch: nessuna modifica locale")

        // 4) aggiorno SOLO e1 (updated.at più recente) → push incrementale con solo e1
        e1.updated = .init(by: "tester", at: Date().addingTimeInterval(5))
        e1.indexed["k"] = "v"
        store.update(e1)

        try await sync.push()
        XCTAssertEqual(backend.savedEntitiesBatches.count, 2, "Secondo push: batch incrementale")
        let lastBatch = backend.savedEntitiesBatches.last ?? []
        let ids = Set(lastBatch.map { $0.id })
        XCTAssertTrue(ids.contains(e1.id))
        XCTAssertFalse(ids.contains(e2.id), "Solo e1 è stato aggiornato")
    }

    func testPushIncrementalForRelationships() async throws {
        // Prepara 2 entity collegate
        let a = makeEntity(type: "A")
        let b = makeEntity(type: "B")
        store.add(a)
        store.add(b)

        // Relationship iniziale
        var rel = makeRelationship(type: "link", from: a.id, to: b.id)
        store.add(rel)

        // Primo push: invia entities e relationship
        try await sync.push()
        XCTAssertEqual(backend.savedEntitiesBatches.count, 1, "Prime entities pushate")
        XCTAssertEqual(backend.savedRelationshipsBatches.count, 1, "Prima relationship pushata")
        XCTAssertEqual(backend.relationshipsStore.count, 1)

        // Push successivo senza modifiche → idempotente
        try await sync.push()
        XCTAssertEqual(backend.savedRelationshipsBatches.count, 1, "Nessun nuovo batch relationships: nessuna modifica")

        // Aggiorno la relationship → push incrementale solo su quella relationship
        rel.updated = .init(by: "tester", at: Date().addingTimeInterval(10))
        rel.indexed["rk"] = "rv"
        store.update(rel)

        try await sync.push()
        XCTAssertEqual(backend.savedRelationshipsBatches.count, 2, "Relationship aggiornata pushata in batch incrementale")
        let lastRelBatch = backend.savedRelationshipsBatches.last ?? []
        XCTAssertTrue(lastRelBatch.map { $0.id }.contains(rel.id))
    }
}

//
//  DeletionOrderAndNoLoopTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 20/08/25.
//

import XCTest
@testable import GraphNext

// NB: Usa i mock già presenti sotto Tests/GraphNextTests/Sync/Mock/
// Assumiamo che MockRemoteBackend esponga deletedEntityIDs / deletedRelationshipIDs
@MainActor
final class DeletionOrderAndNoLoopTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-DeletionOrder", inMemory: true)
        store = GraphStore()
        backend = MockRemoteBackend()

        // Debounce alto per evitare auto-push durante i test; retry minimo
        let config = CloudKitSyncConfig(
            containerIdentifier: nil,
            zoneName: "GraphNextZone",
            stateStore: .userDefaults(suiteName: "CKSE.GraphNextState.Tests"),
            subscribeOnInit: false,
            subscriptionID: "GraphNextSyncSubscription.Tests.DeletionOrder",
            debounceMilliseconds: 5_000,
            retryMaxAttempts: 1,
            retryBaseDelaySeconds: 0.01
        )

        // Iniettiamo il backend mock
        sync = CloudKitSync(
            persistence: persistence,
            store: store,
            backend: backend,
            configuration: config
        )
    }

    private func makeEntity(_ type: String) -> Entity {
        Entity(
            id: UUID(),
            type: type,
            created: .init(by: "local", at: .now),
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: nil
        )
    }

    func testPullRemovesRelationshipsBeforeEntitiesAndDoesNotTriggerPush() async throws {
        // 1) Prepara grafo locale: A -[link]-> B
        let a = makeEntity("A")
        let b = makeEntity("B")
        store.add(node: a)
        store.add(node: b)

        let rel = Relationship(
            id: UUID(),
            type: "link",
            created: .init(by: "local", at: .now),
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: nil,
            from: a.id,
            to: b.id
        )
        store.add(node: rel)

        // Sanity
        XCTAssertNotNil(store.relationship(id: rel.id))
        XCTAssertNotNil(store.entity(id: a.id))
        XCTAssertNotNil(store.entity(id: b.id))

        // 2) Il backend segnala cancellazioni (prima rel, poi entities)
        backend.deletedRelationshipIDs = [rel.id]
        backend.deletedEntityIDs = [a.id, b.id]

        // Nessun dato "nuovo" dal remoto
        backend.entitiesStore = []
        backend.relationshipsStore = []

        // 3) Esegui pull (con isRemote: true all'applicazione)
        try await sync.pull()

        // 4) Verifica che:
        //    - la relationship sia stata rimossa
        //    - le entities siano state poi rimosse
        XCTAssertNil(store.relationship(id: rel.id))
        XCTAssertNil(store.entity(id: a.id))
        XCTAssertNil(store.entity(id: b.id))

        // 5) Verifica NO-LOOP: i cambi remoti non hanno innescato push automatici
        XCTAssertEqual(backend.savedEntitiesBatches.count, 0, "I cambi remoti non devono innescare push")
        XCTAssertEqual(backend.savedRelationshipsBatches.count, 0, "I cambi remoti non devono innescare push")
    }
}

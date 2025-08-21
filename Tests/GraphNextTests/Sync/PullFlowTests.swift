//
//  PullFlowTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/08/25.
//

import XCTest
@testable import GraphNext

final class PullFlowTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-Pull", inMemory: true)
        store = GraphStore()
        backend = MockRemoteBackend()

        let config = CloudKitSyncConfig(
            containerIdentifier: nil,
            zoneName: "GraphNextZone",
            stateStore: .userDefaults(suiteName: "CKSE.GraphNextState.Tests"),
            subscribeOnInit: false,
            subscriptionID: "GraphNextSyncSubscription.Tests.Pull",
            debounceMilliseconds: 50,
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

    private func makeEntity(type: String = "E", at: Date = .now, payload: GraphPayload? = nil) -> Entity {
        Entity(
            id: UUID(),
            type: type,
            created: .init(by: "remote", at: at),
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
            created: .init(by: "remote", at: at),
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

    func testPullPopulatesStoreFromBackend() async throws {
        // Prepara dati "remoti"
        let e1 = makeEntity(type: "Remote-1")
        let e2 = makeEntity(type: "Remote-2")
        backend.entitiesStore = [e1, e2]

        let r = makeRelationship(type: "link", from: e1.id, to: e2.id)
        backend.relationshipsStore = [r]

        // Store vuoto all'inizio
        XCTAssertTrue(store.entities.isEmpty)
        XCTAssertTrue(store.relationships.isEmpty)

        try await sync.pull()

        // Dopo il pull, lo store deve riflettere i dati remoti
        XCTAssertEqual(store.entities.count, 2)
        XCTAssertNotNil(store.entities[e1.id])
        XCTAssertNotNil(store.entities[e2.id])

        XCTAssertEqual(store.relationships.count, 1)
        XCTAssertNotNil(store.relationships[r.id])
        XCTAssertEqual(store.relationships[r.id]?.from, e1.id)
        XCTAssertEqual(store.relationships[r.id]?.to, e2.id)
    }

    func testPullAppliesRemoteWinsOverLocal() async throws {
        // Local entity con dati iniziali
        var local = makeEntity(type: "Local")
        store.add(local)

        // Remoto con stesso id ma dati "più nuovi" (updated più recente)
        var remote = local
        remote.type = "RemoteNewType"
        remote.updated = .init(by: "remote", at: Date().addingTimeInterval(10))
        backend.entitiesStore = [remote]

        // Prima del pull, lo store ha la versione locale
        XCTAssertEqual(store.entities[local.id]?.type, "Local")

        try await sync.pull()

        // Dopo il pull, deve prevalere il remoto (remote-wins)
        XCTAssertEqual(store.entities[local.id]?.type, "RemoteNewType")
        XCTAssertEqual(store.entities.count, 1)
    }
    
    func testPullIsIdempotentWhenNoChanges() async throws {
        // Prepara dati remoti iniziali
        let e1 = makeEntity(type: "Idem-1")
        let e2 = makeEntity(type: "Idem-2")
        backend.entitiesStore = [e1, e2]
        let r = makeRelationship(type: "link", from: e1.id, to: e2.id)
        backend.relationshipsStore = [r]

        // Primo pull
        try await sync.pull()
        XCTAssertEqual(store.entities.count, 2)
        XCTAssertEqual(store.relationships.count, 1)

        // Snapshot dopo il primo pull
        let entitiesSnapshot = store.entities
        let relationshipsSnapshot = store.relationships

        // Secondo pull senza alcuna modifica remota
        try await sync.pull()

        // Idempotenza: lo store non deve cambiare
        XCTAssertEqual(store.entities.count, 2)
        XCTAssertEqual(store.relationships.count, 1)
        XCTAssertEqual(store.entities, entitiesSnapshot)
        XCTAssertEqual(store.relationships, relationshipsSnapshot)
    }
}

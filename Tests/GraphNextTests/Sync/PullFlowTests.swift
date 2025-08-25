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
        store = await GraphStore()
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
        let emptyEntities = await store.allEntities()
        XCTAssertTrue(emptyEntities.isEmpty)
        let emptyRelationships = await store.allRelationships()
        XCTAssertTrue(emptyRelationships.isEmpty)

        try await sync.pull()

        // Dopo il pull, lo store deve riflettere i dati remoti
        let allEntities = await store.allEntities()
        XCTAssertEqual(allEntities.count, 2)
        let entity1 = await store.entity(id: e1.id)
        XCTAssertNotNil(entity1)
        let entity2 = await store.entity(id: e2.id)
        XCTAssertNotNil(entity2)

        let allRelationships = await store.allRelationships()
        XCTAssertEqual(allRelationships.count, 1)
        let rel = await store.relationship(id: r.id)
        XCTAssertNotNil(rel)
        XCTAssertEqual(rel?.from, e1.id)
        XCTAssertEqual(rel?.to, e2.id)
    }

    func testPullAppliesRemoteWinsOverLocal() async throws {
        // Local entity con dati iniziali
        let local = makeEntity(type: "Local")
        await store.add(node: local, isRemote: false)

        // Remoto con stesso id ma dati "più nuovi" (updated più recente)
        var remote = local
        remote.type = "RemoteNewType"
        remote.updated = .init(by: "remote", at: Date().addingTimeInterval(10))
        backend.entitiesStore = [remote]

        // Prima del pull, lo store ha la versione locale
        let prePullEntity = await store.entity(id: local.id)
        XCTAssertEqual(prePullEntity?.type, "Local")

        try await sync.pull()

        // Dopo il pull, deve prevalere il remoto (remote-wins)
        let postPullEntity = await store.entity(id: local.id)
        XCTAssertEqual(postPullEntity?.type, "RemoteNewType")
        let finalEntities = await store.allEntities()
        XCTAssertEqual(finalEntities.count, 1)
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
        let firstEntities = await store.allEntities()
        XCTAssertEqual(firstEntities.count, 2)
        let firstRelationships = await store.allRelationships()
        XCTAssertEqual(firstRelationships.count, 1)

        // Snapshot dopo il primo pull
        let entitiesSnapshot = await store.allEntities()
        let relationshipsSnapshot = await store.allRelationships()

        // Secondo pull senza alcuna modifica remota
        try await sync.pull()

        // Idempotenza: lo store non deve cambiare
        let secondEntities = await store.allEntities()
        XCTAssertEqual(secondEntities, entitiesSnapshot)
        let secondRelationships = await store.allRelationships()
        XCTAssertEqual(secondRelationships, relationshipsSnapshot)
    }
}

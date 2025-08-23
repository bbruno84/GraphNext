//
//  ResetFlowTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/08/25.
//

import XCTest
@testable import GraphNext

final class ResetFlowTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-Reset", inMemory: true)
        store = await GraphStore()
        backend = MockRemoteBackend()

        let config = CloudKitSyncConfig(
            containerIdentifier: nil,
            zoneName: "GraphNextZone",
            stateStore: .userDefaults(suiteName: "CKSE.GraphNextState.Tests"),
            subscribeOnInit: false,
            subscriptionID: "GraphNextSyncSubscription.Tests.Reset",
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

    private func makeEntity(_ type: String = "E") -> Entity {
        Entity(id: UUID(), type: type, created: .init(by: "t", at: .now))
    }

    func testResetClearsAndRepullsFromBackend() async throws {
        // 1) Popola store locale
        let localA = makeEntity("Local-A")
        let localB = makeEntity("Local-B")
        await store.add(node: localA, isRemote: false)
        await store.add(node: localB, isRemote: false)
        let allBefore = await store.entities(ofType: nil)
        XCTAssertEqual(allBefore.count, 2)

        // 2) Prepara dati remoti
        let remote1 = makeEntity("Remote-1")
        let remote2 = makeEntity("Remote-2")
        backend.entitiesStore = [remote1, remote2]

        // 3) Esegui reset → clear + pull remoto
        try await sync.reset()

        // 4) Lo store deve riflettere i dati remoti (locali spariti)
        let allAfter = await store.entities(ofType: nil)
        XCTAssertEqual(allAfter.count, 2)
        let remote1Entity = await store.entity(id: remote1.id)
        XCTAssertNotNil(remote1Entity)

        let remote2Entity = await store.entity(id: remote2.id)
        XCTAssertNotNil(remote2Entity)

        let localAEntity = await store.entity(id: localA.id)
        XCTAssertNil(localAEntity)

        let localBEntity = await store.entity(id: localB.id)
        XCTAssertNil(localBEntity)
    }
}

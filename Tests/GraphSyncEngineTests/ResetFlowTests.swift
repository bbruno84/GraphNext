//
//  ResetFlowTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/08/25.
//

import XCTest
import GraphNext
import GraphPersistence
@testable import GraphSyncEngine

final class ResetFlowTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-Reset", inMemory: true)
        store = GraphStore()
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
        store.add(localA)
        store.add(localB)
        XCTAssertEqual(store.entities.count, 2)

        // 2) Prepara dati remoti
        let remote1 = makeEntity("Remote-1")
        let remote2 = makeEntity("Remote-2")
        backend.entitiesStore = [remote1, remote2]

        // 3) Esegui reset → clear + pull remoto
        try await sync.reset()

        // 4) Lo store deve riflettere i dati remoti (locali spariti)
        XCTAssertEqual(store.entities.count, 2)
        XCTAssertNotNil(store.entities[remote1.id])
        XCTAssertNotNil(store.entities[remote2.id])
        XCTAssertNil(store.entities[localA.id])
        XCTAssertNil(store.entities[localB.id])
    }
}

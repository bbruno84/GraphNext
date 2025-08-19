//
//  DebounceTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/08/25.
//

import XCTest
import GraphNext
import GraphPersistence
@testable import GraphSyncEngine

final class DebounceTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-Debounce", inMemory: true)
        store = GraphStore()
        backend = MockRemoteBackend()

        // Config con debounce ridotto per test veloci
        let config = CloudKitSyncConfig(
            containerIdentifier: nil,
            zoneName: "GraphNextZone",
            stateStore: .userDefaults(suiteName: "CKSE.GraphNextState.Tests"),
            subscribeOnInit: false,
            subscriptionID: "GraphNextSyncSubscription.Tests",
            debounceMilliseconds: 100
        )

        // Iniettiamo il backend mock per evitare CloudKit reale
        sync = await CloudKitSync(
            persistence: persistence,
            store: store,
            backend: backend,
            configuration: config
        )
    }

    func testMultipleTriggersCoalesceIntoSinglePull() async throws {
        // Tre trigger ravvicinati (< 100ms)
        sync.triggerPullDebounced()
        sync.triggerPullDebounced()
        sync.triggerPullDebounced()

        // Attendi oltre la finestra di debounce (100ms) per consentire l'esecuzione del pull
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        // Verifica: un solo ciclo delta (prepareDeltaFetch chiamato una volta)
        XCTAssertEqual(
            backend.prepareDeltaFetchCount,
            1,
            "I trigger debounced dovrebbero coalescere in un solo pull()"
        )
    }
}

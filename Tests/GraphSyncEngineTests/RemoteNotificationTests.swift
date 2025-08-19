//
//  RemoteNotificationTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/08/25.
//

import XCTest
import GraphNext
import GraphPersistence
@testable import GraphSyncEngine

final class RemoteNotificationTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-RemoteNotif", inMemory: true)
        store = GraphStore()
        backend = MockRemoteBackend()

        // Debounce breve per test rapidi
        let config = CloudKitSyncConfig(
            containerIdentifier: nil,
            zoneName: "GraphNextZone",
            stateStore: .userDefaults(suiteName: "CKSE.GraphNextState.Tests"),
            subscribeOnInit: false,
            subscriptionID: "GraphNextSyncSubscription.Tests.Remote",
            debounceMilliseconds: 80,
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

    private func makeEntity(_ type: String = "R") -> Entity {
        Entity(id: UUID(), type: type, created: .init(by: "remote", at: .now))
    }

    func testTriggerPullDebouncedFetchesRemoteData() async throws {
        // Prepara backend “remoto”
        let e = makeEntity("FromRemote")
        backend.entitiesStore = [e]

        // Simula arrivo notifica: usiamo direttamente il trigger debounced
        sync.triggerPullDebounced()

        // Attendi oltre la finestra debounce
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Lo store deve essere popolato dal remoto
        XCTAssertEqual(store.entities.count, 1)
        XCTAssertNotNil(store.entities[e.id])
    }
}

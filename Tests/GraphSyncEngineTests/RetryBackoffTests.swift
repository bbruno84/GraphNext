//
//  RetryBackoffTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/08/25.
//

import XCTest
import GraphNext
import GraphPersistence
@testable import GraphSyncEngine

final class RetryBackoffTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: TransientErrorMockBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-RetryBackoff", inMemory: true)
        store = GraphStore()
    }

    func testPullRetrySucceedsOnThirdAttempt() async throws {
        // falliscono i primi 2 tentativi, il 3° riesce
        backend = TransientErrorMockBackend(failAttemptsBeforeSuccess: 2)

        // debounce breve e retry configurati
        let config = CloudKitSyncConfig(
            containerIdentifier: nil,
            zoneName: "GraphNextZone",
            stateStore: .userDefaults(suiteName: "CKSE.GraphNextState.Tests"),
            subscribeOnInit: false,
            subscriptionID: "GraphNextSyncSubscription.Tests",
            debounceMilliseconds: 50,
            retryMaxAttempts: 3,
            retryBaseDelaySeconds: 0.05 // piccolo delay per test veloci
        )

        sync = await CloudKitSync(
            persistence: persistence,
            store: store,
            backend: backend,
            configuration: config
        )

        // Un singolo trigger debounced → il pull verrà ritentato fino a riuscire
        sync.triggerPullDebounced()

        // Attendi oltre la finestra di debounce + backoff cumulato:
        // debounce 50ms + (50ms + 100ms) di backoff ~ 200-300ms → mettiamo 600ms per sicurezza
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Verifica: prepareDeltaFetch è stato chiamato 3 volte (2 fallimenti + 1 successo)
        XCTAssertEqual(backend.prepareDeltaFetchCount, 3, "Dovrebbe aver tentato 3 volte (retryMaxAttempts)")
        // E solo l'ultimo tentativo ha proseguito a fetchare i dati
        XCTAssertEqual(backend.fetchEntitiesCount, 1, "fetchEntities dovrebbe essere chiamato solo dopo un prepareDeltaFetch riuscito")
        XCTAssertEqual(backend.fetchRelationshipsCount, 1)
    }

    func testPullRetryStopsAfterMaxAttempts() async throws {
        // Configuriamo il backend per fallire almeno 3 volte, ma il max tentativi è 2 → non riuscirà
        backend = TransientErrorMockBackend(failAttemptsBeforeSuccess: 3)

        let config = CloudKitSyncConfig(
            containerIdentifier: nil,
            zoneName: "GraphNextZone",
            stateStore: .userDefaults(suiteName: "CKSE.GraphNextState.Tests"),
            subscribeOnInit: false,
            subscriptionID: "GraphNextSyncSubscription.Tests.2",
            debounceMilliseconds: 50,
            retryMaxAttempts: 2,         // limite basso per test
            retryBaseDelaySeconds: 0.05
        )

        sync = await CloudKitSync(
            persistence: persistence,
            store: store,
            backend: backend,
            configuration: config
        )

        sync.triggerPullDebounced()

        // Attendi debounce + due backoff da ~50ms e ~100ms → mettiamo 400ms
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Verifica: si è fermato al numero massimo di tentativi
        XCTAssertEqual(backend.prepareDeltaFetchCount, 2, "Dovrebbe fermarsi dopo retryMaxAttempts")
        // Non essendo mai riuscito, non deve aver fetchato dati
        XCTAssertEqual(backend.fetchEntitiesCount, 0)
        XCTAssertEqual(backend.fetchRelationshipsCount, 0)
    }
}

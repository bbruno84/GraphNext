//
//  AutoPushTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/08/25.
//

import XCTest
import GraphNext
import GraphPersistence
@testable import GraphSyncEngine

final class AutoPushTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-AutoPush", inMemory: true)
        store = GraphStore()
        backend = MockRemoteBackend()

        // Config con debounce molto basso per test rapidi
        let config = CloudKitSyncConfig(
            containerIdentifier: nil,
            zoneName: "GraphNextZone",
            stateStore: .userDefaults(suiteName: "CKSE.GraphNextState.Tests"),
            subscribeOnInit: false,
            subscriptionID: "GraphNextSyncSubscription.Tests.AutoPush",
            debounceMilliseconds: 80,      // debounce breve
            retryMaxAttempts: 1,            // retry non necessario qui
            retryBaseDelaySeconds: 0.01
        )

        // Iniettiamo il backend mock per evitare CloudKit reale
        sync = await CloudKitSync(
            persistence: persistence,
            store: store,
            backend: backend,
            configuration: config
        )
        // Nota: CloudKitSync avvia automaticamente l'osservazione dello store in init
    }

    // MARK: - Helpers

    private func makeEntity(type: String = "Test", payload: GraphPayload? = nil) -> Entity {
        Entity(
            id: UUID(),
            type: type,
            created: .init(by: "test", at: .now),
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: payload
        )
    }

    private func makeRelationship(type: String = "Rel", from: UUID, to: UUID) -> Relationship {
        Relationship(
            id: UUID(),
            type: type,
            created: .init(by: "test", at: .now),
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

    func testAutoPushOnEntityAdd() async throws {
        let e = makeEntity(type: "AutoPush-1")
        store.add(e)

        // Attendi oltre la finestra di debounce per consentire il push
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        // Verifica che il backend abbia ricevuto almeno un batch di entities
        XCTAssertEqual(backend.savedEntitiesBatches.count, 1, "Dovrebbe essere stato eseguito un push per l'entity aggiunta")
        XCTAssertEqual(backend.entitiesStore.count, 1)
        XCTAssertEqual(backend.entitiesStore.first?.id, e.id)
    }

    func testCoalescesMultipleChangesIntoSinglePush() async throws {
        // due entità aggiunte molto ravvicinate (< debounce)
        let e1 = makeEntity(type: "AutoPush-2a")
        let e2 = makeEntity(type: "AutoPush-2b")

        store.add(e1)
        store.add(e2)

        // Attendi oltre la finestra di debounce
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms

        // Verifica: un solo batch, ma contenente entrambe le entità
        XCTAssertEqual(backend.savedEntitiesBatches.count, 1, "I cambiamenti ravvicinati dovrebbero essere coalesciti in un solo push")
        let batch = backend.savedEntitiesBatches.first ?? []
        let batchIDs = Set(batch.map { $0.id })
        XCTAssertTrue(batchIDs.contains(e1.id))
        XCTAssertTrue(batchIDs.contains(e2.id))
    }

    func testAutoPushOnRelationshipAdd() async throws {
        // Prepara due entity collegate
        let a = makeEntity(type: "A")
        let b = makeEntity(type: "B")
        store.add(a)
        store.add(b)

        // Attendi il push delle entity
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Aggiungi una relationship e verifica il push
        let rel = makeRelationship(type: "link", from: a.id, to: b.id)
        store.add(rel)

        try? await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(backend.savedRelationshipsBatches.count, 1, "Dovrebbe essere stato eseguito un push per la relationship aggiunta")
        let relBatch = backend.savedRelationshipsBatches.first ?? []
        XCTAssertTrue(relBatch.map { $0.id }.contains(rel.id))
    }

    func testIncrementalPushOnEntityUpdate() async throws {
        // 1) inserisci entity → primo push
        var e = makeEntity(type: "UpdateMe")
        store.add(e)
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(backend.savedEntitiesBatches.count, 1, "Inserimento iniziale dovrebbe aver causato un push")

        // 2) aggiorna la stessa entity (updated.at più recente) → secondo push solo con quell'entity
        e.updated = .init(by: "tester", at: .now)
        e.indexed["k"] = "v"
        store.update(e)

        try? await Task.sleep(nanoseconds: 300_000_000)

        // Dovremmo avere un secondo batch
        XCTAssertEqual(backend.savedEntitiesBatches.count, 2, "L'update dovrebbe aver causato un ulteriore push incrementale")
        let lastBatch = backend.savedEntitiesBatches.last ?? []
        XCTAssertTrue(lastBatch.map { $0.id }.contains(e.id), "L'ultima batch deve contenere l'entity aggiornata")
    }
    
    func testIncrementalPushOnRelationshipUpdate() async throws {
        // Prepara due entity collegate
        let a = makeEntity(type: "A")
        let b = makeEntity(type: "B")
        store.add(a)
        store.add(b)
        try? await Task.sleep(nanoseconds: 250_000_000) // attendi push entities

        // 1) inserisci relationship → primo push relationships
        var rel = makeRelationship(type: "link", from: a.id, to: b.id)
        store.add(rel)
        try? await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(
            backend.savedRelationshipsBatches.count, 1,
            "Inserimento iniziale della relationship dovrebbe aver causato un push"
        )

        // 2) aggiorna la stessa relationship (updated.at più recente) → secondo push solo con quella relationship
        rel.updated = .init(by: "tester", at: .now)
        rel.indexed["rk"] = "rv"
        store.update(rel)

        try? await Task.sleep(nanoseconds: 300_000_000)

        // Dovremmo avere un secondo batch
        XCTAssertEqual(
            backend.savedRelationshipsBatches.count, 2,
            "L'update della relationship deve causare un ulteriore push incrementale"
        )
        let lastBatch = backend.savedRelationshipsBatches.last ?? []
        XCTAssertTrue(
            lastBatch.map { $0.id }.contains(rel.id),
            "L'ultimo batch deve contenere la relationship aggiornata"
        )
    }
}

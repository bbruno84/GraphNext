//
//  DeltaDeletionTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 17/08/25.
//

import XCTest
import GraphNext
import GraphPersistence
@testable import GraphSyncEngine

final class DeltaDeletionTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-DeltaDeletion", inMemory: true)
        store = GraphStore()
        backend = MockRemoteBackend()
        sync = await CloudKitSync(persistence: persistence, store: store, backend: backend)
    }

    func testPullAppliesDeletionsBeforeUpserts() async throws {
        // 1) Precarichiamo lo store locale con una entity e una relationship
        let orphanID = UUID()
        let eLocal = Entity(id: orphanID, type: "Local", created: .init(by: "l", at: .now))
        store.add(eLocal)

        // 2) Simuliamo che il backend indichi la cancellazione di quella entity
        backend.deletedEntityIDsBuffer = [orphanID]

        // 3) E contemporaneamente fornisca nuovi oggetti remoti
        let newEntity = Entity(id: UUID(), type: "Remote", created: .init(by: "r", at: .now))
        backend.entitiesStore = [newEntity]
        backend.relationshipsStore = []

        // 4) Esegui il pull (delta): prima applica deletions, poi upsert
        try await sync.pull()

        // 5) Verifiche: la entity cancellata deve sparire
        XCTAssertNil(store.entities[orphanID], "La entity da cancellare dovrebbe essere stata rimossa dallo store")

        // E la nuova entity remota deve essere presente
        XCTAssertNotNil(store.entities[newEntity.id], "La nuova entity remota dovrebbe essere stata aggiunta allo store")
    }

    func testPullNoDeletionsKeepsLocal() async throws {
        // Nessuna deletion, solo delta con nuovi oggetti
        let local = Entity(id: UUID(), type: "Keep", created: .init(by: "l", at: .now))
        store.add(local)

        let remote = Entity(id: UUID(), type: "Remote", created: .init(by: "r", at: .now))
        backend.entitiesStore = [remote]

        try await sync.pull()

        // Local rimane, remote arriva
        XCTAssertNotNil(store.entities[local.id])
        XCTAssertNotNil(store.entities[remote.id])
    }
    
    func testPullAppliesRelationshipDeletionsBeforeUpserts() async throws {
        // Setup base: due entity locali collegate da una relationship locale
        let aID = UUID()
        let bID = UUID()
        let relID = UUID()

        let eA = Entity(id: aID, type: "A", created: .init(by: "l", at: .now))
        let eB = Entity(id: bID, type: "B", created: .init(by: "l", at: .now))
        store.add(eA)
        store.add(eB)

        let relLocal = Relationship(
            id: relID,
            type: "link",
            created: .init(by: "l", at: .now),
            from: aID,
            to: bID
        )
        store.add(relLocal)

        // Simuliamo: il backend segnala la cancellazione della relationship esistente
        backend.deletedRelationshipIDsBuffer = [relID]

        // ...e contemporaneamente fornisce una nuova relationship remota (upsert)
        let newRelID = UUID()
        let newRel = Relationship(
            id: newRelID,
            type: "link",
            created: .init(by: "r", at: .now),
            from: aID,
            to: bID
        )
        backend.relationshipsStore = [newRel]

        // Esegui il pull: prima deletions, poi upsert
        try await sync.pull()

        // La relazione cancellata deve sparire
        XCTAssertNil(store.relationships[relID], "La relationship \(relID) dovrebbe essere stata rimossa dallo store")

        // La nuova relazione remota deve essere presente
        XCTAssertEqual(store.relationships[newRelID]?.id, newRelID, "La nuova relationship remota dovrebbe essere stata aggiunta allo store")
    }
}

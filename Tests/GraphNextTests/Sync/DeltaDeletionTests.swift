//
//  DeltaDeletionTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 17/08/25.
//

import XCTest
@testable import GraphNext

final class DeltaDeletionTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext-DeltaDeletion", inMemory: true)
        store = await GraphStore()
        backend = MockRemoteBackend()
        sync = await CloudKitSync(persistence: persistence, store: store, backend: backend)
    }

    func testPullAppliesDeletionsBeforeUpserts() async throws {
        // 1) Precarichiamo lo store locale con una entity e una relationship
        let orphanID = UUID()
        let eLocal = Entity(id: orphanID, type: "Local", created: .init(by: "l", at: .now))
        await store.add(node: eLocal, isRemote: false)

        // 2) Simuliamo che il backend indichi la cancellazione di quella entity
        backend.deletedEntityIDsBuffer = [orphanID]

        // 3) E contemporaneamente fornisca nuovi oggetti remoti
        let newEntity = Entity(id: UUID(), type: "Remote", created: .init(by: "r", at: .now))
        backend.entitiesStore = [newEntity]
        backend.relationshipsStore = []

        // 4) Esegui il pull (delta): prima applica deletions, poi upsert
        try await sync.pull()

        // 5) Verifiche: la entity cancellata deve sparire
        let deletedEntity = await store.entity(id: orphanID)
        XCTAssertNil(deletedEntity, "La entity da cancellare dovrebbe essere stata rimossa dallo store")

        // E la nuova entity remota deve essere presente
        let addedEntity = await store.entity(id: newEntity.id)
        XCTAssertNotNil(addedEntity, "La nuova entity remota dovrebbe essere stata aggiunta allo store")
    }

    func testPullNoDeletionsKeepsLocal() async throws {
        // Nessuna deletion, solo delta con nuovi oggetti
        let local = Entity(id: UUID(), type: "Keep", created: .init(by: "l", at: .now))
        await store.add(node: local, isRemote: false)

        let remote = Entity(id: UUID(), type: "Remote", created: .init(by: "r", at: .now))
        backend.entitiesStore = [remote]

        try await sync.pull()

        // Local rimane, remote arriva
        let keptEntity = await store.entity(id: local.id)
        XCTAssertNotNil(keptEntity)
        let remoteEntity = await store.entity(id: remote.id)
        XCTAssertNotNil(remoteEntity)
    }
    
    func testPullAppliesRelationshipDeletionsBeforeUpserts() async throws {
        // Setup base: due entity locali collegate da una relationship locale
        let aID = UUID()
        let bID = UUID()
        let relID = UUID()

        let eA = Entity(id: aID, type: "A", created: .init(by: "l", at: .now))
        let eB = Entity(id: bID, type: "B", created: .init(by: "l", at: .now))
        await store.add(node: eA, isRemote: false)
        await store.add(node: eB, isRemote: false)

        let relLocal = Relationship(
            id: relID,
            type: "link",
            created: .init(by: "l", at: .now),
            from: aID,
            to: bID
        )
        await store.add(node: relLocal, isRemote: false)

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
        let deletedRelationship = await store.relationship(id: relID)
        XCTAssertNil(deletedRelationship, "La relationship \(relID) dovrebbe essere stata rimossa dallo store")

        // La nuova relazione remota deve essere presente
        let newRelationship = await store.relationship(id: newRelID)
        XCTAssertEqual(newRelationship?.id, newRelID, "La nuova relationship remota dovrebbe essere stata aggiunta allo store")
    }
}

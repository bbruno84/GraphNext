//
//  MockRemoteBackend.swift
//  GraphNext
//
//  Created by Valerio Buriani on 12/08/25.
//

import Foundation
import GraphNext
@testable import GraphSyncEngine

final class MockRemoteBackend: RemoteSyncBackend {
    var entitiesStore: [Entity]
    var relationshipsStore: [Relationship]

    private(set) var savedEntitiesBatches: [[Entity]] = []
    private(set) var savedRelationshipsBatches: [[Relationship]] = []
    private(set) var fetchEntitiesCount = 0
    private(set) var fetchRelationshipsCount = 0
    private(set) var prepareDeltaFetchCount = 0

    // Delta buffers (simulate one delta cycle)
    var deletedEntityIDsBuffer: [UUID] = []
    var deletedRelationshipIDsBuffer: [UUID] = []

    init(entities: [Entity] = [], relationships: [Relationship] = []) {
        self.entitiesStore = entities
        self.relationshipsStore = relationships
    }

    // MARK: - RemoteSyncBackend (Delta lifecycle)

    func prepareDeltaFetch() async throws {
        // Simula l'avvio di un ciclo delta
        prepareDeltaFetchCount += 1
    }

    func fetchEntities() async throws -> [Entity] {
        fetchEntitiesCount += 1
        return entitiesStore
    }

    func fetchRelationships() async throws -> [Relationship] {
        fetchRelationshipsCount += 1
        return relationshipsStore
    }

    func save(entities: [Entity]) async throws {
        savedEntitiesBatches.append(entities)
        entitiesStore.append(contentsOf: entities)
    }

    func save(relationships: [Relationship]) async throws {
        savedRelationshipsBatches.append(relationships)
        relationshipsStore.append(contentsOf: relationships)
    }

    func resetRemote() async throws {
        entitiesStore.removeAll()
        relationshipsStore.removeAll()
        deletedEntityIDsBuffer.removeAll()
        deletedRelationshipIDsBuffer.removeAll()
    }

    func fetchDeletedEntityIDs() async throws -> [UUID] {
        let ids = deletedEntityIDsBuffer
        deletedEntityIDsBuffer.removeAll()
        return ids
    }

    func fetchDeletedRelationshipIDs() async throws -> [UUID] {
        let ids = deletedRelationshipIDsBuffer
        deletedRelationshipIDsBuffer.removeAll()
        return ids
    }
}

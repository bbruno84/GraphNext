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

    init(entities: [Entity] = [], relationships: [Relationship] = []) {
        self.entitiesStore = entities
        self.relationshipsStore = relationships
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
    }
}

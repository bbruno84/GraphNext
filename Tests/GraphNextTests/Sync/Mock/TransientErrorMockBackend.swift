//
//  TransientErrorMockBackend.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/08/25.
//

import Foundation
@testable import GraphNext
import CloudKit

/// Mock backend che simula errori transitori su prepareDeltaFetch()
/// per testare il retry/backoff del CloudKitSync (via triggerPullDebounced()).
final class TransientErrorMockBackend: RemoteSyncBackend {
    // Config: numero di tentativi che devono fallire prima di riuscire
    private let failAttemptsBeforeSuccess: Int
    private var attempts: Int = 0

    // Dati “remoti” fittizi
    var entitiesStore: [Entity] = []
    var relationshipsStore: [Relationship] = []

    // Contatori per asserzioni nei test
    private(set) var prepareDeltaFetchCount = 0
    private(set) var fetchEntitiesCount = 0
    private(set) var fetchRelationshipsCount = 0

    init(failAttemptsBeforeSuccess: Int,
         entities: [Entity] = [],
         relationships: [Relationship] = []) {
        self.failAttemptsBeforeSuccess = failAttemptsBeforeSuccess
        self.entitiesStore = entities
        self.relationshipsStore = relationships
    }

    // MARK: - RemoteSyncBackend

    func prepareDeltaFetch() async throws {
        prepareDeltaFetchCount += 1
        attempts += 1

        if attempts <= failAttemptsBeforeSuccess {
            // Simula un errore transitorio (rate limiting)
            throw CKError(.requestRateLimited)
        }
        // altrimenti: successo (no-op)
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
        // non usato in questi test
    }

    func save(relationships: [Relationship]) async throws {
        // non usato in questi test
    }

    func resetRemote() async throws {
        entitiesStore.removeAll()
        relationshipsStore.removeAll()
    }

    func fetchDeletedEntityIDs() async throws -> [UUID] { [] }
    func fetchDeletedRelationshipIDs() async throws -> [UUID] { [] }

    func subscribeToRemoteChanges() async throws {
        // no-op nei test
    }
}

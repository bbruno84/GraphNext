//
//  RemoteSyncBackend.swift
//  GraphNext
//
//  Created by Valerio Buriani on 12/08/25.
//
import Foundation

// internal: non fa parte dell'API pubblica del package
internal protocol RemoteSyncBackend {
    func prepareDeltaFetch() async throws
    func fetchEntities() async throws -> [Entity]
    func fetchRelationships() async throws -> [Relationship]
    func save(entities: [Entity]) async throws
    func save(relationships: [Relationship]) async throws
    func resetRemote() async throws
    func fetchDeletedEntityIDs() async throws -> [UUID]
    func fetchDeletedRelationshipIDs() async throws -> [UUID]
    func subscribeToRemoteChanges() async throws
}

internal extension RemoteSyncBackend {
    func prepareDeltaFetch() async throws { /* default: no-op */ }
    func resetRemote() async throws { /* default: no-op */ }
    func fetchDeletedEntityIDs() async throws -> [UUID] { [] }
    func fetchDeletedRelationshipIDs() async throws -> [UUID] { [] }
    func subscribeToRemoteChanges() async throws { /* default: no-op */ }
}

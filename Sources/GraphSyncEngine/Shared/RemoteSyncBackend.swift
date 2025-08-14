//
//  RemoteSyncBackend.swift
//  GraphNext
//
//  Created by Valerio Buriani on 12/08/25.
//
import Foundation
import GraphNext

// internal: non fa parte dell'API pubblica del package
internal protocol RemoteSyncBackend {
    func fetchEntities() async throws -> [Entity]
    func fetchRelationships() async throws -> [Relationship]
    func save(entities: [Entity]) async throws
    func save(relationships: [Relationship]) async throws
    func resetRemote() async throws
}

extension RemoteSyncBackend {
    func resetRemote() async throws { /* default: no-op */ }
}

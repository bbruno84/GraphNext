//
//  CloudKitSync+Pull.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//
import Foundation

extension CloudKitSync {
    @MainActor
    public func pull() async throws {
        isSyncing = true
        defer { isSyncing = false }
        // Prepara il delta sul backend (riempie i buffer per questo ciclo)
        try await backend.prepareDeltaFetch()

        // Applica deletions prima degli inserimenti/aggiornamenti (remote authoritative)
        let deletedEntityIDs = try await backend.fetchDeletedEntityIDs()
        let deletedRelationshipIDs = try await backend.fetchDeletedRelationshipIDs()

        // Prima rimuovi le relationship per evitare referenze pendenti
        for id in deletedRelationshipIDs {
            store.remove(id: id, isRemote: true)
        }
        // Poi rimuovi le entity
        for id in deletedEntityIDs {
            store.remove(id: id, isRemote: true)
        }

        let entities = try await backend.fetchEntities()
        let relationships = try await backend.fetchRelationships()

        for e in entities { store.add(node: e, isRemote: true) }
        for r in relationships { store.add(node: r, isRemote: true) }
    }
}

//
//  CloudKitSync+Pull.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//
import Foundation

extension CloudKitSync {
    public func pull() async throws {
        isSyncing = true
        defer { isSyncing = false }
        // Prepara il delta sul backend (riempie i buffer per questo ciclo)
        try await backend.prepareDeltaFetch()

        // Applica deletions prima degli inserimenti/aggiornamenti (remote authoritative)
        let deletedEntityIDs = try await backend.fetchDeletedEntityIDs()
        let deletedRelationshipIDs = try await backend.fetchDeletedRelationshipIDs()

        for id in deletedEntityIDs {
            // Rimuovi l'entity dallo store se presente
            // (metodo di store previsto: removeEntity(_:))
            store.removeNode(id: id)
        }
        for id in deletedRelationshipIDs {
            // Rimuovi la relationship dallo store se presente
            // (metodo di store previsto: removeRelationship(_:))
            store.removeNode(id: id)
        }

        let entities = try await backend.fetchEntities()
        let relationships = try await backend.fetchRelationships()

        for e in entities { store.add(e) }
        for r in relationships { store.add(r) }
    }
}

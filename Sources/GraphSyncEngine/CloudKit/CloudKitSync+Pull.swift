//
//  CloudKitSync+Pull.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//
import Foundation
import GraphNext

extension CloudKitSync {
    public func pull() async throws {
        isSyncing = true
        defer { isSyncing = false }

        let entities = try await backend.fetchEntities()
        let relationships = try await backend.fetchRelationships()

        for e in entities { store.add(e) }
        for r in relationships { store.add(r) }
    }
}

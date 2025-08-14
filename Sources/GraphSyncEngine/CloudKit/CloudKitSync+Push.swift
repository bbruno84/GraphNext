//
//  CloudKitSync+Push.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation
import GraphNext

extension CloudKitSync {
    public func push() async throws {
        isSyncing = true
        defer { isSyncing = false }

        let entitiesToPush = store.allEntities()
        let relationshipsToPush = store.allRelationships()

        try await backend.save(entities: entitiesToPush)
        try await backend.save(relationships: relationshipsToPush)
    }
}

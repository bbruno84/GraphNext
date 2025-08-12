//
//  CloudKitSync+Push.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation
import CloudKit
import GraphNext

extension CloudKitSync {
    public func push() async throws {
        let entitiesToPush = store.allEntities()
        let relationshipsToPush = store.allRelationships()
        
        for entity in entitiesToPush {
            let record = entity.asCKRecord()
            try await save(record)
        }

        for relationship in relationshipsToPush {
            let record = relationship.asCKRecord()
            try await save(record)
        }
    }

    private func save(_ record: CKRecord) async throws {
        try await container.privateCloudDatabase.save(record)
    }
}


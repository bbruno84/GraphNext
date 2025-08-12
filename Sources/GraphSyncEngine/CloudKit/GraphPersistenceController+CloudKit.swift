//
//  GraphPersistenceController+CloudKit.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation
import CloudKit
import GraphPersistence
import GraphNext
import CoreData

extension GraphPersistenceController {
    
    public func saveEntities(from records: [CKRecord]) {
        for record in records {
            guard
                let uuidString = record["uuid"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let type = record["type"] as? String,
                let payloadData = record["payload"] as? Data,
                let payload = try? JSONDecoder().decode([String: GraphPayloadValue].self, from: payloadData),
                let indexedData = record["indexed"] as? Data,
                let indexed = try? JSONDecoder().decode([String: String].self, from: indexedData),
                let createdBy = record["createdBy"] as? String,
                let createdAt = record["createdAt"] as? Date
            else { continue }
            
            let sharedWith = record["sharedWith"] as? [String] ?? []
            let updatedBy = record["updatedBy"] as? String
            let updatedAt = record["updatedAt"] as? Date
            
            let createdInfo = AuditInfo(by: createdBy, at: createdAt)
            let updatedInfo: AuditInfo? = {
                if let updatedBy, let updatedAt {
                    return AuditInfo(by: updatedBy, at: updatedAt)
                } else {
                    return nil
                }
            }()
            
            let entity = Entity(
                id: uuid,
                type: type,
                indexed: indexed,
                created: createdInfo,
                updated: updatedInfo,
                sharedWith: sharedWith,
                payload: payload
            )
            
            try? save(node: entity)
        }
    }
    
    public func saveRelationships(from records: [CKRecord]) {
        for record in records {
            guard
                let uuidString = record["uuid"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let type = record["type"] as? String,
                let sourceUUIDString = record["sourceUUID"] as? String,
                let sourceUUID = UUID(uuidString: sourceUUIDString),
                let targetUUIDString = record["targetUUID"] as? String,
                let targetUUID = UUID(uuidString: targetUUIDString),
                let createdBy = record["createdBy"] as? String,
                let createdAt = record["createdAt"] as? Date
            else { continue }
            
            let sharedWith = record["sharedWith"] as? [String] ?? []
            let updatedBy = record["updatedBy"] as? String
            let updatedAt = record["updatedAt"] as? Date
            
            let createdInfo = AuditInfo(by: createdBy, at: createdAt)
            let updatedInfo: AuditInfo? = {
                if let updatedBy, let updatedAt {
                    return AuditInfo(by: updatedBy, at: updatedAt)
                } else {
                    return nil
                }
            }()
            
            let relationship = Relationship(
                id: uuid,
                type: type,
                tag: [],
                group: [],
                created: createdInfo,
                updated: updatedInfo,
                version: nil,
                sharedWith: sharedWith,
                permissions: nil,
                from: sourceUUID,
                to: targetUUID
            )

            
            try? save(node: relationship)
        }
    }
}

//
//  CKRecord+Init.swift
//  GraphNext
//
//  Created by Valerio Buriani on 03/08/25.
//
import Foundation
import CloudKit
import GraphNext

extension Entity {
    public init?(from record: CKRecord) {
        guard let uuidString = record["uuid"] as? String,
              let uuid = UUID(uuidString: uuidString),
              let type = record["type"] as? String,
              let createdBy = record["createdBy"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        let indexed = (try? JSONDecoder().decode([String: String].self, from: record["indexed"] as? Data ?? Data())) ?? [:]
        let payload = (try? JSONDecoder().decode(GraphPayload.self, from: record["payload"] as? Data ?? Data()))
        let sharedWith = record["sharedWith"] as? [String] ?? []
        let created = AuditInfo(by: createdBy, at: createdAt)

        let updated: AuditInfo?
        if let updatedBy = record["updatedBy"] as? String,
           let updatedAt = record["updatedAt"] as? Date {
            updated = AuditInfo(by: updatedBy, at: updatedAt)
        } else {
            updated = nil
        }

        self.init(
            id: uuid,
            type: type,
            tag: [],
            group: [],
            indexed: indexed,
            created: created,
            updated: updated,
            version: nil,
            sharedWith: sharedWith,
            permissions: nil,
            payload: payload
        )
    }
}

extension Relationship {
    public init?(from record: CKRecord) {
        guard let uuidString = record["uuid"] as? String,
              let uuid = UUID(uuidString: uuidString),
              let type = record["type"] as? String,
              let createdBy = record["createdBy"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        let from = (record["sourceUUID"] as? String).flatMap(UUID.init(uuidString:))
        let to = (record["targetUUID"] as? String).flatMap(UUID.init(uuidString:))
        let sharedWith = record["sharedWith"] as? [String] ?? []
        let created = AuditInfo(by: createdBy, at: createdAt)

        let updated: AuditInfo?
        if let updatedBy = record["updatedBy"] as? String,
           let updatedAt = record["updatedAt"] as? Date {
            updated = AuditInfo(by: updatedBy, at: updatedAt)
        } else {
            updated = nil
        }

        self.init(
            id: uuid,
            type: type,
            tag: [],
            group: [],
            indexed: [:],
            created: created,
            updated: updated,
            version: nil,
            sharedWith: sharedWith,
            permissions: nil,
            payload: nil,
            from: from,
            to: to
        )
    }
}



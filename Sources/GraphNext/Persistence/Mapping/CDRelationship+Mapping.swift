//
//  CDRelationship+Mapping.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import Foundation
import CoreData

extension CDRelationship {
    func populate(from relationship: Relationship) {
        id = relationship.id
        type = relationship.type
        tag = relationship.tag as NSSet
        group = relationship.group as NSSet
        indexed = relationship.indexed as NSDictionary
        created = try? JSONEncoder().encode(relationship.created)
        updatedAt = try? JSONEncoder().encode(relationship.updated)
        version = relationship.version.map { Int64($0) } ?? 0
        sharedWith = relationship.sharedWith as NSArray
        permissions = try? JSONEncoder().encode(relationship.permissions)
        payload = try? JSONEncoder().encode(relationship.payload)
        from = relationship.from
        to = relationship.to
    }

    func toRelationship() -> Relationship {
        return Relationship(
            id: id!,
            type: type!,
            tag: (tag as? Set<String>) ?? [],
            group: (group as? Set<String>) ?? [],
            indexed: (indexed as? [String: String]) ?? [:],
            created: (try? JSONDecoder().decode(AuditInfo.self, from: created ?? Data())) ?? .init(by: "unknown", at: .distantPast),
            updated: (try? JSONDecoder().decode(AuditInfo.self, from: updatedAt ?? Data())),
            version: Int(version),
            sharedWith: (sharedWith as? [String]) ?? [],
            permissions: (try? JSONDecoder().decode(Permissions.self, from: permissions ?? Data())),
            payload: (try? JSONDecoder().decode(GraphPayload.self, from: payload ?? Data())),
            from: from,
            to: to
        )
    }
}


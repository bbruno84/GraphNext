//
//  CDEntity+Mapping.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//
import Foundation
import CoreData
import GraphNext

extension CDEntity {
    func populate(from entity: Entity) {
        id = entity.id
        type = entity.type
        tag = entity.tag as NSSet
        group = entity.group as NSSet
        indexed = entity.indexed as NSDictionary
        created = try? JSONEncoder().encode(entity.created)
        updatedAt = try? JSONEncoder().encode(entity.updated)
        version = entity.version.map { Int64($0) } ?? 0 // Convertiamo in modo sicuro
        sharedWith = entity.sharedWith as NSArray
        permissions = try? JSONEncoder().encode(entity.permissions)
        payload = try? JSONEncoder().encode(entity.payload)
    }

    func toEntity() -> Entity {
        return Entity(
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
            payload: (try? JSONDecoder().decode(GraphPayload.self, from: payload ?? Data()))
        )
    }
}




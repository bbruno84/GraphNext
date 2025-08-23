//
//  Entity.swift
//  GraphNext
//
//  Created by Valerio Buriani on 21/08/25.
//

import Foundation

// MARK: - Entity
public struct Entity: GraphNode {
    public var id: UUID
    public var type: String
    public var tag: Set<String> = []
    public var group: Set<String> = []
    public var created: AuditInfo
    public var updated: AuditInfo?
    public var version: Int?
    public var sharedWith: [String] = []
    public var permissions: Permissions?
    public var payload: GraphPayload?
    
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id == rhs.id &&
            lhs.type == rhs.type &&
            lhs.tag == rhs.tag &&
            lhs.group == rhs.group &&
            lhs.created == rhs.created &&
            lhs.updated == rhs.updated &&
            lhs.version == rhs.version &&
            lhs.sharedWith == rhs.sharedWith &&
            lhs.permissions == rhs.permissions
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
        hasher.combine(tag)
        hasher.combine(group)
        hasher.combine(created)
        hasher.combine(updated)
        hasher.combine(version)
        hasher.combine(sharedWith)
        hasher.combine(permissions)
    }
    
    public init(
            id: UUID,
            type: String,
            tag: Set<String> = [],
            group: Set<String> = [],
            created: AuditInfo,
            updated: AuditInfo? = nil,
            version: Int? = nil,
            sharedWith: [String] = [],
            permissions: Permissions? = nil,
            payload: GraphPayload? = nil
        ) {
            self.id = id
            self.type = type
            self.tag = tag
            self.group = group
            self.created = created
            self.updated = updated
            self.version = version
            self.sharedWith = sharedWith
            self.permissions = permissions
            self.payload = payload
        }


}

//
//  GraphStore.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import Foundation
import Combine

// MARK: - GraphNode Protocol
public protocol GraphNode: Identifiable, Hashable {
    var id: UUID { get }
    var type: String { get }
    var tag: Set<String> { get set }
    var group: Set<String> { get set }
    var indexed: [String: String] { get set }
    var created: AuditInfo { get set }
    var updated: AuditInfo? { get set }
    var version: Int? { get set }
    var sharedWith: [String] { get set }
    var permissions: Permissions? { get set }
}

// MARK: - Entity
public struct Entity: GraphNode {
    public var id: UUID
    public var type: String
    public var tag: Set<String> = []
    public var group: Set<String> = []
    public var indexed: [String: String] = [:]
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
            lhs.indexed == rhs.indexed &&
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
        hasher.combine(indexed)
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
            indexed: [String: String] = [:],
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
            self.indexed = indexed
            self.created = created
            self.updated = updated
            self.version = version
            self.sharedWith = sharedWith
            self.permissions = permissions
            self.payload = payload
        }


}

// MARK: - Relationship
public struct Relationship: GraphNode {
    public var id: UUID
    public var type: String
    public var from: UUID?
    public var to: UUID?
    public var tag: Set<String> = []
    public var group: Set<String> = []
    public var indexed: [String: String] = [:]
    public var created: AuditInfo
    public var updated: AuditInfo?
    public var version: Int?
    public var sharedWith: [String] = []
    public var permissions: Permissions?
    public var payload: GraphPayload?
    
    public static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        return lhs.id == rhs.id &&
            lhs.type == rhs.type &&
            lhs.from == rhs.from &&
            lhs.to == rhs.to &&
            lhs.tag == rhs.tag &&
            lhs.group == rhs.group &&
            lhs.indexed == rhs.indexed &&
            lhs.created == rhs.created &&
            lhs.updated == rhs.updated &&
            lhs.version == rhs.version &&
            lhs.sharedWith == rhs.sharedWith &&
            lhs.permissions == rhs.permissions
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
        hasher.combine(from)
        hasher.combine(to)
        hasher.combine(tag)
        hasher.combine(group)
        hasher.combine(indexed)
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
        indexed: [String: String] = [:],
        created: AuditInfo,
        updated: AuditInfo? = nil,
        version: Int? = nil,
        sharedWith: [String] = [],
        permissions: Permissions? = nil,
        payload: GraphPayload? = nil,
        from: UUID? = nil,
        to: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.tag = tag
        self.group = group
        self.indexed = indexed
        self.created = created
        self.updated = updated
        self.version = version
        self.sharedWith = sharedWith
        self.permissions = permissions
        self.payload = payload
        self.from = from
        self.to = to
    }
}

// MARK: - GraphStore (ObservableObject)
public final class GraphStore: ObservableObject {
    @Published private(set) public var entities: [UUID: Entity] = [:]
    @Published private(set) public var relationships: [UUID: Relationship] = [:]

    private var cache: NSCache<NSString, AnyObject>?

    public init(useNSCache: Bool = false) {
        if useNSCache {
            self.cache = NSCache<NSString, AnyObject>()
        }
    }

    public func add(_ node: any GraphNode) {
        switch node {
        case let entity as Entity:
            entities[entity.id] = entity
            cache?.setObject(entity as AnyObject, forKey: entity.id.uuidString as NSString)
        case let relationship as Relationship:
            relationships[relationship.id] = relationship
            cache?.setObject(relationship as AnyObject, forKey: relationship.id.uuidString as NSString)
        default:
            break
        }
    }

    public func update(_ node: any GraphNode) {
        add(node)
    }

    public func removeNode(id: UUID) {
        entities.removeValue(forKey: id)
        relationships.removeValue(forKey: id)
        cache?.removeObject(forKey: id.uuidString as NSString)
    }

    public func entity(id: UUID) -> Entity? {
        if let cached = cache?.object(forKey: id.uuidString as NSString) as? Entity {
            return cached
        }
        return entities[id]
    }

    public func relationship(id: UUID) -> Relationship? {
        if let cached = cache?.object(forKey: id.uuidString as NSString) as? Relationship {
            return cached
        }
        return relationships[id]
    }

    public func entities(ofType type: String? = nil) -> [Entity] {
        if let type = type {
            return entities.values.filter { $0.type == type }
        }
        return Array(entities.values)
    }

    public func entities(tagged tag: String) -> [Entity] {
        return entities.values.filter { $0.tag.contains(tag) }
    }

    public func relationships(from id: UUID) -> [Relationship] {
        return relationships.values.filter { $0.from == id }
    }

    public func relationships(to id: UUID) -> [Relationship] {
        return relationships.values.filter { $0.to == id }
    }

    public func relatedEntities(from id: UUID) -> [Entity] {
        let relatedIDs = relationships(from: id).compactMap { $0.to }
        return relatedIDs.compactMap { entities[$0] }
    }
}


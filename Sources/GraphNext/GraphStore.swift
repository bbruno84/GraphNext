//
//  GraphStore.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import Foundation
import Combine

// MARK: - Common Protocol

public protocol GraphNode: Identifiable, Hashable, Equatable {
    var id: UUID { get }
    var type: String { get }
    var tags: Set<String> { get }
}

// MARK: - Entity

public final class Entity: GraphNode {
    public let id: UUID
    public var type: String
    public var tags: Set<String>
    
    public init(id: UUID = UUID(), type: String, tags: Set<String> = []) {
        self.id = id
        self.type = type
        self.tags = tags
    }
    
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Relationship

public final class Relationship: GraphNode {
    public let id: UUID
    public var type: String
    public var tags: Set<String>
    public let from: UUID
    public let to: UUID
    
    public init(id: UUID = UUID(), type: String, tags: Set<String> = [], from: UUID, to: UUID) {
        self.id = id
        self.type = type
        self.tags = tags
        self.from = from
        self.to = to
    }
    
    public static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - GraphStore

public protocol GraphStoreProtocol: AnyObject, ObservableObject {
    func add(node: any GraphNode)
    func update(node: any GraphNode)
    func remove(id: UUID)
    
    func entity(id: UUID) -> Entity?
    func relationship(id: UUID) -> Relationship?
    
    func entities(ofType type: String?) -> [Entity]
    func entities(tagged tag: String) -> [Entity]
    
    func relationships(from id: UUID) -> [Relationship]
    func relationships(to id: UUID) -> [Relationship]
    
    func relatedEntities(from id: UUID) -> [Entity]
}

public final class GraphStore: GraphStoreProtocol {
    public let objectWillChange = ObservableObjectPublisher()
    
    private var entities: [UUID: Entity] = [:]
    private var relationships: [UUID: Relationship] = [:]
    
    private var cache: NSCache<NSString, AnyObject>?
    
    public init(cacheEnabled: Bool = true, cacheSizeLimit: Int = 1000) {
        if cacheEnabled {
            let cache = NSCache<NSString, AnyObject>()
            cache.countLimit = cacheSizeLimit
            self.cache = cache
        }
    }
    
    public func add(node: any GraphNode) {
        objectWillChange.send()
        if let entity = node as? Entity {
            entities[entity.id] = entity
            cache?.setObject(entity, forKey: entity.id.uuidString as NSString)
        } else if let relationship = node as? Relationship {
            relationships[relationship.id] = relationship
            cache?.setObject(relationship, forKey: relationship.id.uuidString as NSString)
        }
    }
    
    public func update(node: any GraphNode) {
        add(node: node)
    }
    
    public func remove(id: UUID) {
        objectWillChange.send()
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
    
    public func entities(ofType type: String?) -> [Entity] {
        let values = entities.values
        if let type = type {
            return values.filter { $0.type == type }
        }
        return Array(values)
    }
    
    public func entities(tagged tag: String) -> [Entity] {
        return entities.values.filter { $0.tags.contains(tag) }
    }
    
    public func relationships(from id: UUID) -> [Relationship] {
        return relationships.values.filter { $0.from == id }
    }
    
    public func relationships(to id: UUID) -> [Relationship] {
        return relationships.values.filter { $0.to == id }
    }
    
    public func relatedEntities(from id: UUID) -> [Entity] {
        let toIDs = relationships(from: id).map { $0.to }
        return toIDs.compactMap { entities[$0] }
    }
}

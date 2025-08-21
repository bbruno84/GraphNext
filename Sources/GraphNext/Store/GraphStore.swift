//
//  GraphStore.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import Foundation
import Combine

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
    
    public func clear() {
        entities.removeAll()
        relationships.removeAll()
    }

}


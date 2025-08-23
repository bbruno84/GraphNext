import Foundation
#if canImport(Combine)
import Combine
#endif

@MainActor
public final class GraphStore: @preconcurrency ObservableObject {
    
    public let objectWillChange = ObservableObjectPublisher()
    
    private var entities: [UUID: Entity] = [:]
    internal var relationships: [UUID: Relationship] = [:]
    
    private var cache: NSCache<NSString, Box<AnyObject>>?
    
    #if canImport(Combine)
    private let changeSubject = PassthroughSubject<Change, Never>()
    public var changeFeed: AnyPublisher<Change, Never> {
        changeSubject.eraseToAnyPublisher()
    }
    #endif
    
    public init(useNSCache: Bool = true, cacheSizeLimit: Int = 1000) {
        if useNSCache {
            let cache = NSCache<NSString, Box<AnyObject>>()
            cache.countLimit = cacheSizeLimit
            self.cache = cache
        }
    }
    
    public func add(node: any GraphNode, isRemote: Bool = false) {
        objectWillChange.send()
        if let entity = node as? Entity {
            entities[entity.id] = entity
            cache?.setObject(Box(entity as AnyObject), forKey: entity.id.uuidString as NSString)
            #if canImport(Combine)
            changeSubject.send(.insert(node: entity, isRemote: isRemote))
            #endif
        } else if let relationship = node as? Relationship {
            relationships[relationship.id] = relationship
            cache?.setObject(Box(relationship as AnyObject), forKey: relationship.id.uuidString as NSString)
            #if canImport(Combine)
            changeSubject.send(.insert(node: relationship, isRemote: isRemote))
            #endif
        }
    }
    
    public func update(node: any GraphNode, isRemote: Bool = false) {
        add(node: node, isRemote: isRemote)
        #if canImport(Combine)
        changeSubject.send(.update(node: node, isRemote: isRemote))
        #endif
    }
    
    public func remove(id: UUID, isRemote: Bool = false) {
        objectWillChange.send()
        entities.removeValue(forKey: id)
        relationships.removeValue(forKey: id)
        cache?.removeObject(forKey: id.uuidString as NSString)
        #if canImport(Combine)
        changeSubject.send(.remove(id: id, isRemote: isRemote))
        #endif
    }
    
    public func entity(id: UUID) -> Entity? {
        if let cached = cache?.object(forKey: id.uuidString as NSString)?.value as? Entity {
            return cached
        }
        return entities[id]
    }
    
    public func relationship(id: UUID) -> Relationship? {
        if let cached = cache?.object(forKey: id.uuidString as NSString)?.value as? Relationship {
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
        return entities.values.filter { entity in
            entity.tag.contains(tag)
        }
    }
    
    public func relationships(from id: UUID) -> [Relationship] {
        return relationships.values.compactMap { rel in
            guard let from = rel.from else { return nil }
            return from == id ? rel : nil
        }
    }
    
    public func relationships(to id: UUID) -> [Relationship] {
        return relationships.values.compactMap { rel in
            guard let to = rel.to else { return nil }
            return to == id ? rel : nil
        }
    }
    
    public func relatedEntities(from id: UUID) -> [Entity] {
        let toIDs = relationships(from: id).compactMap { $0.to }
        return toIDs.compactMap { entities[$0] }
    }
    
    public func clear(isRemote: Bool = false) {
        for entity in entities.values {
            remove(id: entity.id, isRemote: isRemote)
        }
        for relationship in relationships.values {
            remove(id: relationship.id, isRemote: isRemote)
        }
    }

}

// MARK: - Change enum

#if canImport(Combine)
public enum Change {
    case insert(node: any GraphNode, isRemote: Bool)
    case update(node: any GraphNode, isRemote: Bool)
    case remove(id: UUID, isRemote: Bool)
}
#endif

//
//  CoreDataGraphPersistenceController.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import Foundation
import CoreData

public final class CoreDataGraphPersistenceController {
    
    private let container: NSPersistentContainer
    
    // Assets helper
    private var assetStorage: AssetStorage { AssetStorageProvider.shared.storage }

    // Reuse a single NSManagedObjectModel across the process to avoid Core Data
    // warnings about multiple models claiming the same NSManagedObject subclasses.
    private static let sharedModel: NSManagedObjectModel = {
        // 1) Exact momd in SwiftPM resources
        if let url = Bundle.module.url(forResource: "GraphNext", withExtension: "momd"),
           let m = NSManagedObjectModel(contentsOf: url), !m.entities.isEmpty { return m }
        // 2) Some toolchains expose a single .mom inside the .momd directory
        if let url = Bundle.module.url(forResource: "Model", withExtension: "mom", subdirectory: "GraphNext.momd"),
           let m = NSManagedObjectModel(contentsOf: url), !m.entities.isEmpty { return m }
        // 3) Xcode unit tests context
        let classBundle = Bundle(for: CoreDataGraphPersistenceController.self)
        if let url = classBundle.url(forResource: "GraphNext", withExtension: "momd"),
           let m = NSManagedObjectModel(contentsOf: url), !m.entities.isEmpty { return m }
        // 4) Fallback to merged models across known bundles
        if let m = NSManagedObjectModel.mergedModel(from: [Bundle.module, classBundle, Bundle.main]),
           !m.entities.isEmpty { return m }
        fatalError("Failed to load Core Data model 'GraphNext'. Ensure Package.swift includes the Resources folder under the GraphNext target.")
    }()

    public init(storeName: String = "GraphNext", inMemory: Bool = false) {
        let model = Self.sharedModel

        // Sanity check on expected entities
        let names = Set(model.entitiesByName.keys)
        precondition(names.contains("CDEntity") && names.contains("CDRelationship"),
                     "Core Data model missing expected entities. Available: \(names.sorted())")

        // Container + store configuration
        container = NSPersistentContainer(name: storeName, managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = inMemory ? NSInMemoryStoreType : NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error { fatalError("CoreData load error: \(error)") }
        }
    }

    // MARK: - Save

    public func save(node: any GraphNode) throws {
        var thrownError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        container.performBackgroundTask { (context: NSManagedObjectContext) in
            do {
                if let entity = node as? Entity {
                    let cdEntity = self.fetchOrCreateEntity(id: entity.id, in: context)
                    cdEntity.populate(from: entity)
                } else if let relationship = node as? Relationship {
                    let cdRelationship = self.fetchOrCreateRelationship(id: relationship.id, in: context)
                    cdRelationship.populate(from: relationship)
                }
                try context.save()
            } catch {
                thrownError = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        if let error = thrownError {
            throw error
        }
    }

    // MARK: - Load Node

    public func loadNode(id: UUID) throws -> (any GraphNode)? {
        var result: (any GraphNode)?
        let semaphore = DispatchSemaphore(value: 0)
        container.performBackgroundTask { (context: NSManagedObjectContext) in
            if let cdEntity = self.fetchEntity(id: id, in: context) {
                result = cdEntity.toEntity()
            } else if let cdRelationship = self.fetchRelationship(id: id, in: context) {
                result = cdRelationship.toRelationship()
            }
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    // MARK: - All Nodes

    public func allNodes(ofType type: String) throws -> [any GraphNode] {
        var result: [any GraphNode] = []
        var thrownError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        container.performBackgroundTask { (context: NSManagedObjectContext) in
            do {
                let entityRequest: NSFetchRequest<CDEntity> = CDEntity.fetchRequest()
                let relationshipRequest: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
                entityRequest.predicate = NSPredicate(format: "type == %@", type)
                relationshipRequest.predicate = NSPredicate(format: "type == %@", type)

                let entities = try context.fetch(entityRequest).map { $0.toEntity() }
                let relationships = try context.fetch(relationshipRequest).map { $0.toRelationship() }
                result = entities + relationships
            } catch {
                thrownError = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        if let error = thrownError {
            throw error
        }
        return result
    }

    // MARK: - Load Relationships

    public func loadRelationships(from id: UUID) throws -> [Relationship] {
        var result: [Relationship] = []
        var thrownError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        container.performBackgroundTask { (context: NSManagedObjectContext) in
            do {
                let request: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
                request.predicate = NSPredicate(format: "from == %@", id as CVarArg)
                result = try context.fetch(request).map { $0.toRelationship() }
            } catch {
                thrownError = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        if let error = thrownError {
            throw error
        }
        return result
    }

    public func loadRelationships(to id: UUID) throws -> [Relationship] {
        var result: [Relationship] = []
        var thrownError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        container.performBackgroundTask { (context: NSManagedObjectContext) in
            do {
                let request: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
                request.predicate = NSPredicate(format: "to == %@", id as CVarArg)
                result = try context.fetch(request).map { $0.toRelationship() }
            } catch {
                thrownError = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        if let error = thrownError {
            throw error
        }
        return result
    }

    // MARK: - Delete Node

    public func deleteNode(id: UUID) throws {
        var thrownError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        container.performBackgroundTask { (context: NSManagedObjectContext) in
            if let entity = self.fetchEntity(id: id, in: context) {
                // Best-effort: if this is an asset entity, remove the local file before deleting from Core Data
                if entity.type == "asset" {
                    try? self.assetStorage.remove(assetId: id)
                }
                context.delete(entity)
            }
            if let relationship = self.fetchRelationship(id: id, in: context) {
                context.delete(relationship)
            }
            do {
                try context.save()
            } catch {
                thrownError = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        if let error = thrownError {
            throw error
        }
    }

    // MARK: - Private Helpers

    private func fetchOrCreateEntity(id: UUID, in context: NSManagedObjectContext) -> CDEntity {
        if let existing = fetchEntity(id: id, in: context) {
            return existing
        }
        let newEntity = CDEntity(context: context)
        newEntity.id = id
        return newEntity
    }

    private func fetchOrCreateRelationship(id: UUID, in context: NSManagedObjectContext) -> CDRelationship {
        if let existing = fetchRelationship(id: id, in: context) {
            return existing
        }
        let newRelationship = CDRelationship(context: context)
        newRelationship.id = id
        return newRelationship
    }

    private func fetchEntity(id: UUID, in context: NSManagedObjectContext) -> CDEntity? {
        let request: NSFetchRequest<CDEntity> = CDEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }

    private func fetchRelationship(id: UUID, in context: NSManagedObjectContext) -> CDRelationship? {
        let request: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }
    
    // MARK: - Cascade Delete: Entity + Attached Relationships

    public func deleteEntityAndAttachedRelationships(id: UUID) async throws {
        try await container.performBackgroundTask { (context: NSManagedObjectContext) in
            // 1) Elimina relazioni collegate (fetch + delete manuale)
            let relFetch: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
            relFetch.predicate = NSPredicate(format: "from == %@ OR to == %@", id as CVarArg, id as CVarArg)
            relFetch.includesPropertyValues = false
            let rels = try context.fetch(relFetch)
            rels.forEach(context.delete)

            // 2) Elimina l'entity se presente
            if let entity = try self.fetchCDEntity(id: id, in: context) {
                // Best-effort: se è un asset, rimuovi il file locale prima della delete
                if entity.type == "asset" {
                    try? self.assetStorage.remove(assetId: id)
                }
                context.delete(entity)
            }

            // 3) Salvataggio atomico
            if context.hasChanges {
                try context.save()
            }
        }
    }

    // MARK: - Helper per fetch CDEntity

    private func fetchCDEntity(id: UUID, in context: NSManagedObjectContext) throws -> CDEntity? {
        let req: NSFetchRequest<CDEntity> = CDEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try context.fetch(req).first
    }
}

extension CoreDataGraphPersistenceController: GraphPersistenceController {
    
    public func saveEntity(_ entity: Entity) async throws {
        try save(node: entity)
    }

    public func entity(id: UUID) async throws -> Entity? {
        try await withCheckedThrowingContinuation { continuation in
            do {
                if let node = try loadNode(id: id) as? Entity {
                    continuation.resume(returning: node)
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func deleteEntity(id: UUID) async throws {
        try deleteNode(id: id)
    }

    public func saveEntities(_ entities: [Entity]) async throws {
        for entity in entities {
            try await saveEntity(entity)
        }
    }

    public func deleteEntities(_ ids: [UUID]) async throws {
        for id in ids {
            try await deleteEntity(id: id)
        }
    }

    public func saveRelationship(_ relationship: Relationship) async throws {
        try save(node: relationship)
    }

    public func relationship(id: UUID) async throws -> Relationship? {
        try await withCheckedThrowingContinuation { continuation in
            do {
                if let node = try loadNode(id: id) as? Relationship {
                    continuation.resume(returning: node)
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func deleteRelationship(id: UUID) async throws {
        try deleteNode(id: id)
    }

    public func saveRelationships(_ relationships: [Relationship]) async throws {
        for relationship in relationships {
            try await saveRelationship(relationship)
        }
    }

    public func deleteRelationships(_ ids: [UUID]) async throws {
        for id in ids {
            try await deleteRelationship(id: id)
        }
    }

    public func allEntities() async throws -> [Entity] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let all = try allNodes(ofType: "") // recupera tutto, filtraggio opzionale
                let entities = all.compactMap { $0 as? Entity }
                continuation.resume(returning: entities)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func allRelationships() async throws -> [Relationship] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let all = try allNodes(ofType: "") // recupera tutto, filtraggio opzionale
                let relationships = all.compactMap { $0 as? Relationship }
                continuation.resume(returning: relationships)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func reset() async throws {
        throw NSError(domain: "GraphNext.CoreData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Reset non implementato in CoreDataGraphPersistenceController"])
    }

    public func queryEntities(matching type: String?) async throws -> [Entity] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let nodes = try allNodes(ofType: type ?? "")
                let entities = nodes.compactMap { $0 as? Entity }
                continuation.resume(returning: entities)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func queryRelationships(matching type: String?) async throws -> [Relationship] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let nodes = try allNodes(ofType: type ?? "")
                let relationships = nodes.compactMap { $0 as? Relationship }
                continuation.resume(returning: relationships)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

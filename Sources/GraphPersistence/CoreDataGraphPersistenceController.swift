//
//  CoreDataGraphPersistenceController.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import Foundation
import CoreData
import GraphNext

public final class CoreDataGraphPersistenceController: GraphPersistenceController {
    
    private let container: NSPersistentContainer

    public init(storeName: String = "GraphNext", inMemory: Bool = false) {
        guard let modelURL = Bundle.module.url(forResource: "GraphNext", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to locate Core Data model GraphNext")
        }

        container = NSPersistentContainer(name: storeName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData load error: \(error)")
            }
        }
    }
    
    private var context: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Save
    
    public func save(node: any GraphNode) throws {
        if let entity = node as? Entity {
            let cdEntity = fetchOrCreateEntity(id: entity.id)
            cdEntity.populate(from: entity)
        } else if let relationship = node as? Relationship {
            let cdRelationship = fetchOrCreateRelationship(id: relationship.id)
            cdRelationship.populate(from: relationship)
        }
        try context.save()
    }

    // MARK: - Load Node
    
    public func loadNode(id: UUID) throws -> (any GraphNode)? {
        if let cdEntity = fetchEntity(id: id) {
            return cdEntity.toEntity()
        }
        if let cdRelationship = fetchRelationship(id: id) {
            return cdRelationship.toRelationship()
        }
        return nil
    }

    // MARK: - All Nodes
    
    public func allNodes(ofType type: String) throws -> [any GraphNode] {
        let entityRequest: NSFetchRequest<CDEntity> = CDEntity.fetchRequest()
        let relationshipRequest: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
        entityRequest.predicate = NSPredicate(format: "type == %@", type)
        relationshipRequest.predicate = NSPredicate(format: "type == %@", type)
        
        let entities = try context.fetch(entityRequest).map { $0.toEntity() }
        let relationships = try context.fetch(relationshipRequest).map { $0.toRelationship() }
        return entities + relationships
    }

    // MARK: - Load Relationships
    
    public func loadRelationships(from id: UUID) throws -> [Relationship] {
        let request: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
        request.predicate = NSPredicate(format: "from == %@", id as CVarArg)
        return try context.fetch(request).map { $0.toRelationship() }
    }

    public func loadRelationships(to id: UUID) throws -> [Relationship] {
        let request: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
        request.predicate = NSPredicate(format: "to == %@", id as CVarArg)
        return try context.fetch(request).map { $0.toRelationship() }
    }

    // MARK: - Delete Node
    
    public func deleteNode(id: UUID) throws {
        if let entity = fetchEntity(id: id) {
            context.delete(entity)
        }
        if let relationship = fetchRelationship(id: id) {
            context.delete(relationship)
        }
        try context.save()
    }

    // MARK: - Private Helpers

    private func fetchOrCreateEntity(id: UUID) -> CDEntity {
        if let existing = fetchEntity(id: id) {
            return existing
        }
        let newEntity = CDEntity(context: context)
        newEntity.id = id
        return newEntity
    }

    private func fetchOrCreateRelationship(id: UUID) -> CDRelationship {
        if let existing = fetchRelationship(id: id) {
            return existing
        }
        let newRelationship = CDRelationship(context: context)
        newRelationship.id = id
        return newRelationship
    }

    private func fetchEntity(id: UUID) -> CDEntity? {
        let request: NSFetchRequest<CDEntity> = CDEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }

    private func fetchRelationship(id: UUID) -> CDRelationship? {
        let request: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }
}

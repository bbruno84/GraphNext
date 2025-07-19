//
//  CoreDataGraphPersistenceController.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import GraphNext
import CoreData
import Foundation

public final class CoreDataGraphPersistenceController: GraphPersistenceController {
    private let container: NSPersistentContainer

    public init(inMemory: Bool = false, storeName: String = "GraphNext") {
        let modelURL = Bundle.module.url(forResource: "GraphNext", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        self.container = NSPersistentContainer(name: storeName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
    }

    private var context: NSManagedObjectContext {
        container.viewContext
    }

    public func save(node: any GraphNode) throws {
        if let entity = node as? Entity {
            let cdEntity = CDEntity(context: context)
            cdEntity.populate(from: entity)
        } else if let relationship = node as? Relationship {
            let cdRelationship = CDRelationship(context: context)
            cdRelationship.populate(from: relationship)
        }
        try context.save()
    }

    public func loadNode(id: UUID) throws -> (any GraphNode)? {
        if let entity = try loadCDEntity(id: id) {
            return entity.toEntity()
        } else if let relationship = try loadCDRelationship(id: id) {
            return relationship.toRelationship()
        }
        return nil
    }

    public func allNodes(ofType type: String) throws -> [any GraphNode] {
        let entityRequest: NSFetchRequest<CDEntity> = CDEntity.fetchRequest()
        entityRequest.predicate = NSPredicate(format: "type == %@", type)
        let entities = try context.fetch(entityRequest)

        let relationshipRequest: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
        relationshipRequest.predicate = NSPredicate(format: "type == %@", type)
        let relationships = try context.fetch(relationshipRequest)

        return entities.map { $0.toEntity() } + relationships.map { $0.toRelationship() }
    }

    public func loadRelationships(from id: UUID) throws -> [Relationship] {
        let request: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
        request.predicate = NSPredicate(format: "from == %@", id as CVarArg)
        let results = try context.fetch(request)
        return results.map { $0.toRelationship() }
    }

    public func loadRelationships(to id: UUID) throws -> [Relationship] {
        let request: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
        request.predicate = NSPredicate(format: "to == %@", id as CVarArg)
        let results = try context.fetch(request)
        return results.map { $0.toRelationship() }
    }

    public func deleteNode(id: UUID) throws {
        if let entity = try loadCDEntity(id: id) {
            context.delete(entity)
        } else if let relationship = try loadCDRelationship(id: id) {
            context.delete(relationship)
        }
        try context.save()
    }

    private func loadCDEntity(id: UUID) throws -> CDEntity? {
        let request: NSFetchRequest<CDEntity> = CDEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func loadCDRelationship(id: UUID) throws -> CDRelationship? {
        let request: NSFetchRequest<CDRelationship> = CDRelationship.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }
}

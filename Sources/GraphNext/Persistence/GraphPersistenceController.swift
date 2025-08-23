//
//  GraphPersistenceController.swift
//  GraphNext
//
//  Created by Regia GraphNext on 23/08/2025.
//

import Foundation

/// Protocollo astratto che rappresenta lo strato di persistenza per GraphNext.
/// Le implementazioni concrete (es. GRDB, Core Data) devono conformare a questo protocollo.
public protocol GraphPersistenceController: AnyObject {
    
    // MARK: - Entity CRUD
    
    func saveEntity(_ entity: Entity) async throws
    func entity(id: UUID) async throws -> Entity?
    func deleteEntity(id: UUID) async throws
    func deleteEntityAndAttachedRelationships(id: UUID) async throws
    
    func saveEntities(_ entities: [Entity]) async throws
    func deleteEntities(_ ids: [UUID]) async throws
    
    // MARK: - Relationship CRUD
    
    func saveRelationship(_ relationship: Relationship) async throws
    func relationship(id: UUID) async throws -> Relationship?
    func deleteRelationship(id: UUID) async throws
    
    func saveRelationships(_ relationships: [Relationship]) async throws
    func deleteRelationships(_ ids: [UUID]) async throws
    
    // MARK: - Fetch
    
    func allEntities() async throws -> [Entity]
    func allRelationships() async throws -> [Relationship]
    
    // MARK: - Reset
    
    func reset() async throws
    
    // MARK: - Query
    func queryEntities(matching type: String?) async throws -> [Entity]
    func queryRelationships(matching type: String?) async throws -> [Relationship]
}

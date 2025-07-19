//
//  GraphPeristenceController.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import Foundation
import GraphNext

import Foundation

public protocol GraphPersistenceController {
    func save(node: any GraphNode) throws
    func loadNode(id: UUID) throws -> (any GraphNode)?
    func allNodes(ofType type: String) throws -> [any GraphNode]
    func loadRelationships(from id: UUID) throws -> [Relationship]
    func loadRelationships(to id: UUID) throws -> [Relationship]
    func deleteNode(id: UUID) throws
}


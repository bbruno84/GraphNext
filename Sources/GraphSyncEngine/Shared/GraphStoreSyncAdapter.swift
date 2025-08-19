//
//  GraphStoreSyncAdapter.swift
//  GraphNext
//
//  Created by Valerio Buriani on 03/08/25.
//
import Foundation
import GraphNext

public protocol GraphStoreSyncAdapter {
    func allEntities() -> [Entity]
    func allRelationships() -> [Relationship]
}

extension GraphStore: GraphStoreSyncAdapter {
    public func allEntities() -> [Entity] {
        return Array(entities.values)
    }

    public func allRelationships() -> [Relationship] {
        return Array(relationships.values)
    }
}



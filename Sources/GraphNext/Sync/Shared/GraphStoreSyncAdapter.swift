//
//  GraphStoreSyncAdapter.swift
//  GraphNext
//
//  Created by Valerio Buriani on 03/08/25.
//
import Foundation

@MainActor
public protocol GraphStoreSyncAdapter {
    func allEntities() -> [Entity]
    func allRelationships() -> [Relationship]
}

extension GraphStore: GraphStoreSyncAdapter {
    public func allEntities() -> [Entity] {
        return entities(ofType: nil)
    }

    public func allRelationships() -> [Relationship] {
        return relationships.values.compactMap { $0 }
    }
}

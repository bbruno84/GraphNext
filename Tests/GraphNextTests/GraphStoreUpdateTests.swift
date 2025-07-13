//
//  GraphStoreUpdateTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import XCTest
@testable import GraphNext

final class GraphStoreUpdateTests: XCTestCase {
    
    func testUpdateReplacesEntity() {
        let store = GraphStore(cacheEnabled: true)
        let id = UUID()
        let entity1 = Entity(id: id, type: "OldType")
        store.add(node: entity1)
        
        let entity2 = Entity(id: id, type: "NewType")
        store.update(node: entity2)
        
        let result = store.entity(id: id)
        XCTAssertEqual(result?.type, "NewType")
    }
    
    func testUpdateReplacesRelationship() {
        let store = GraphStore(cacheEnabled: true)
        let e1 = Entity(type: "A")
        let e2 = Entity(type: "B")
        store.add(node: e1)
        store.add(node: e2)
        
        let id = UUID()
        let rel1 = Relationship(id: id, type: "OldLink", from: e1.id, to: e2.id)
        store.add(node: rel1)
        
        let rel2 = Relationship(id: id, type: "NewLink", from: e1.id, to: e2.id)
        store.update(node: rel2)
        
        let result = store.relationship(id: id)
        XCTAssertEqual(result?.type, "NewLink")
    }
}

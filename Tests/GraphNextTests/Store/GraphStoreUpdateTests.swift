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
        let store = GraphStore(useNSCache: true)
        let id = UUID()
        let entity1 = Entity(
            id: id,
            type: "OldType",
            created: AuditInfo(by: "test")
        )
        store.add(entity1)
        
        let entity2 = Entity(
            id: id,
            type: "NewType",
            created: AuditInfo(by: "test")
        )
        store.update(entity2)
        
        let result = store.entity(id: id)
        XCTAssertEqual(result?.type, "NewType")
    }
    
    func testUpdateReplacesRelationship() {
        let store = GraphStore(useNSCache: true)
        let e1 = Entity(
            id: UUID(),
            type: "A",
            created: AuditInfo(by: "test")
        )
        let e2 = Entity(
            id: UUID(),
            type: "B",
            created: AuditInfo(by: "test")
        )
        store.add(e1)
        store.add(e2)
        
        let id = UUID()
        let rel1 = Relationship(
            id: id,
            type: "OldLink",
            created: AuditInfo(by: "test"),
            from: e1.id,
            to: e2.id
        )
        store.add(rel1)
        
        let rel2 = Relationship(
            id: id,
            type: "NewLink",
            created: AuditInfo(by: "test"),
            from: e1.id,
            to: e2.id
        )
        store.update(rel2)
        
        let result = store.relationship(id: id)
        XCTAssertEqual(result?.type, "NewLink")
    }
}


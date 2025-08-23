//
//  GraphStoreUpdateTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import XCTest
@testable import GraphNext

final class GraphStoreUpdateTests: XCTestCase {
    
    func testUpdateReplacesEntity() async {
        let store = await GraphStore(useNSCache: true)
        let id = UUID()
        let entity1 = Entity(
            id: id,
            type: "OldType",
            created: AuditInfo(by: "test")
        )
        await store.add(node: entity1, isRemote: false)
        
        let entity2 = Entity(
            id: id,
            type: "NewType",
            created: AuditInfo(by: "test")
        )
        await store.update(node: entity2, isRemote: false)
        
        let result = await store.entity(id: id)
        XCTAssertEqual(result?.type, "NewType")
    }
    
    func testUpdateReplacesRelationship() async {
        let store = await GraphStore(useNSCache: true)
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
        await store.add(node: e1, isRemote: false)
        await store.add(node: e2, isRemote: false)
        
        let id = UUID()
        let rel1 = Relationship(
            id: id,
            type: "OldLink",
            created: AuditInfo(by: "test"),
            from: e1.id,
            to: e2.id
        )
        await store.add(node: rel1, isRemote: false)
        
        let rel2 = Relationship(
            id: id,
            type: "NewLink",
            created: AuditInfo(by: "test"),
            from: e1.id,
            to: e2.id
        )
        await store.update(node: rel2, isRemote: false)
        
        let result = await store.relationship(id: id)
        XCTAssertEqual(result?.type, "NewLink")
    }
}


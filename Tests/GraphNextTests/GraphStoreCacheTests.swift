//
//  GraphStoreCacheTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import XCTest
@testable import GraphNext

final class GraphStoreCacheTests: XCTestCase {
    
    func testCacheStoresEntities() {
        let store = GraphStore(useNSCache: true)
        let entity = Entity(
            id: UUID(),
            type: "CacheTest",
            created: AuditInfo(by: "test")
        )
        store.add(entity)
        let cached = store.entity(id: entity.id)
        XCTAssertEqual(cached?.id, entity.id)
    }
    
    func testCacheStoresRelationships() {
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
        let rel = Relationship(
            id: UUID(),
            type: "connects",
            created: AuditInfo(by: "test"),
            from: e1.id,
            to: e2.id
        )
        store.add(e1)
        store.add(e2)
        store.add(rel)
        let cached = store.relationship(id: rel.id)
        XCTAssertEqual(cached?.id, rel.id)
    }
    
    func testCacheInvalidationOnRemove() {
        let store = GraphStore(useNSCache: true)
        let entity = Entity(
            id: UUID(),
            type: "InvalidationTest",
            created: AuditInfo(by: "test")
        )
        store.add(entity)
        XCTAssertNotNil(store.entity(id: entity.id))
        store.removeNode(id: entity.id)
        XCTAssertNil(store.entity(id: entity.id))
    }
}



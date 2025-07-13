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
        let store = GraphStore(cacheEnabled: true)
        let entity = Entity(type: "CacheTest")
        store.add(node: entity)
        let cached = store.entity(id: entity.id)
        XCTAssertEqual(cached?.id, entity.id)
    }
    
    func testCacheStoresRelationships() {
        let store = GraphStore(cacheEnabled: true)
        let e1 = Entity(type: "A")
        let e2 = Entity(type: "B")
        let rel = Relationship(type: "connects", from: e1.id, to: e2.id)
        store.add(node: e1)
        store.add(node: e2)
        store.add(node: rel)
        let cached = store.relationship(id: rel.id)
        XCTAssertEqual(cached?.id, rel.id)
    }
    
    func testCacheInvalidationOnRemove() {
        let store = GraphStore(cacheEnabled: true)
        let entity = Entity(type: "InvalidationTest")
        store.add(node: entity)
        XCTAssertNotNil(store.entity(id: entity.id))
        store.remove(id: entity.id)
        XCTAssertNil(store.entity(id: entity.id))
    }
}

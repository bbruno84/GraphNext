//
//  GraphStoreCacheTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import XCTest
@testable import GraphNext

final class GraphStoreCacheTests: XCTestCase {
    
    func testCacheStoresEntities() async {
        let store = await GraphStore(useNSCache: true)
        let entity = Entity(
            id: UUID(),
            type: "CacheTest",
            created: AuditInfo(by: "test")
        )
        await store.add(node: entity, isRemote: false)
        let cached = await store.entity(id: entity.id)
        XCTAssertEqual(cached?.id, entity.id)
    }
    
    func testCacheStoresRelationships() async {
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
        let rel = Relationship(
            id: UUID(),
            type: "connects",
            created: AuditInfo(by: "test"),
            from: e1.id,
            to: e2.id
        )
        await store.add(node: e1, isRemote: false)
        await store.add(node: e2, isRemote: false)
        await store.add(node: rel, isRemote: false)
        let cached = await store.relationship(id: rel.id)
        XCTAssertEqual(cached?.id, rel.id)
    }
    
    func testCacheInvalidationOnRemove() async {
        let store = await GraphStore(useNSCache: true)
        let entity = Entity(
            id: UUID(),
            type: "InvalidationTest",
            created: AuditInfo(by: "test")
        )
        await store.add(node: entity, isRemote: false)
        let before = await store.entity(id: entity.id)
        XCTAssertNotNil(before)

        await store.remove(id: entity.id, isRemote: false)

        let after = await store.entity(id: entity.id)
        XCTAssertNil(after)
    }
}

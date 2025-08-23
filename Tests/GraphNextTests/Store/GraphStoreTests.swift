//
//  GraphStoreTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//
import XCTest
@testable import GraphNext

final class GraphStoreTests: XCTestCase {
    
    var store: GraphStore!
    
    override func setUp() async throws {
        try await super.setUp()
        store = await GraphStore(useNSCache: true)
    }
    
    override func tearDown() {
        store = nil
        super.tearDown()
    }
    
    func testAddEntity() async {
        var entity = Entity(
            id: UUID(),
            type: "Car",
            created: AuditInfo(by: "test")
        )
        entity.tag = ["test"]
        await store.add(node: entity, isRemote: false)
        let result = await store.entity(id: entity.id)
        XCTAssertEqual(result?.id, entity.id)
        XCTAssertEqual(result?.type, "Car")
        XCTAssertTrue(result?.tag.contains("test") ?? false)
    }
    
    func testRemoveEntity() async {
        let entity = Entity(
            id: UUID(),
            type: "Driver",
            created: AuditInfo(by: "test")
        )
        await store.add(node: entity, isRemote: false)
        await store.remove(id: entity.id, isRemote: false)
        let result = await store.entity(id: entity.id)
        XCTAssertNil(result)
    }
    
    func testEntitiesOfType() async {
        let car = Entity(
            id: UUID(),
            type: "Car",
            created: AuditInfo(by: "test")
        )
        let bike = Entity(
            id: UUID(),
            type: "Bike",
            created: AuditInfo(by: "test")
        )
        await store.add(node: car, isRemote: false)
        await store.add(node: bike, isRemote: false)
        let cars = await store.entities(ofType: "Car")
        XCTAssertEqual(cars.count, 1)
        XCTAssertEqual(cars.first?.id, car.id)
    }
    
    func testEntitiesTagged() async {
        var tagged = Entity(
            id: UUID(),
            type: "Car",
            created: AuditInfo(by: "test")
        )
        tagged.tag = ["fast"]
        
        let untagged = Entity(
            id: UUID(),
            type: "Car",
            created: AuditInfo(by: "test")
        )
        
        await store.add(node: tagged, isRemote: false)
        await store.add(node: untagged, isRemote: false)
        let fastEntities = await store.entities(tagged: "fast")
        XCTAssertEqual(fastEntities.count, 1)
        XCTAssertEqual(fastEntities.first?.id, tagged.id)
    }
    
    func testAddRelationship() async {
        let from = Entity(
            id: UUID(),
            type: "Start",
            created: AuditInfo(by: "test")
        )
        let to = Entity(
            id: UUID(),
            type: "End",
            created: AuditInfo(by: "test")
        )
        let relationship = Relationship(
            id: UUID(),
            type: "Link",
            created: AuditInfo(by: "test"),
            from: from.id,
            to: to.id
        )
        await store.add(node: from, isRemote: false)
        await store.add(node: to, isRemote: false)
        await store.add(node: relationship, isRemote: false)
        let rels = await store.relationships(from: from.id)
        XCTAssertEqual(rels.count, 1)
        XCTAssertEqual(rels.first?.to, to.id)
    }
    
    func testRelatedEntities() async {
        let a = Entity(
            id: UUID(),
            type: "A",
            created: AuditInfo(by: "test")
        )
        let b = Entity(
            id: UUID(),
            type: "B",
            created: AuditInfo(by: "test")
        )
        let rel = Relationship(
            id: UUID(),
            type: "connects",
            created: AuditInfo(by: "test"),
            from: a.id,
            to: b.id
        )
        await store.add(node: a, isRemote: false)
        await store.add(node: b, isRemote: false)
        await store.add(node: rel, isRemote: false)
        let related = await store.relatedEntities(from: a.id)
        XCTAssertEqual(related.count, 1)
        XCTAssertEqual(related.first?.id, b.id)
    }
}

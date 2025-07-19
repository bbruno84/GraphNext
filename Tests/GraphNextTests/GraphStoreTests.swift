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
    
    override func setUp() {
        super.setUp()
        store = GraphStore(useNSCache: true)
    }
    
    override func tearDown() {
        store = nil
        super.tearDown()
    }
    
    func testAddEntity() {
        var entity = Entity(
            id: UUID(),
            type: "Car",
            created: AuditInfo(by: "test")
        )
        entity.tag = ["test"]
        store.add(entity)
        let result = store.entity(id: entity.id)
        XCTAssertEqual(result?.id, entity.id)
        XCTAssertEqual(result?.type, "Car")
        XCTAssertTrue(result?.tag.contains("test") ?? false)
    }
    
    func testRemoveEntity() {
        let entity = Entity(
            id: UUID(),
            type: "Driver",
            created: AuditInfo(by: "test")
        )
        store.add(entity)
        store.removeNode(id: entity.id)
        XCTAssertNil(store.entity(id: entity.id))
    }
    
    func testEntitiesOfType() {
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
        store.add(car)
        store.add(bike)
        let cars = store.entities(ofType: "Car")
        XCTAssertEqual(cars.count, 1)
        XCTAssertEqual(cars.first?.id, car.id)
    }
    
    func testEntitiesTagged() {
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
        
        store.add(tagged)
        store.add(untagged)
        let fastEntities = store.entities(tagged: "fast")
        XCTAssertEqual(fastEntities.count, 1)
        XCTAssertEqual(fastEntities.first?.id, tagged.id)
    }
    
    func testAddRelationship() {
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
        store.add(from)
        store.add(to)
        store.add(relationship)
        let rels = store.relationships(from: from.id)
        XCTAssertEqual(rels.count, 1)
        XCTAssertEqual(rels.first?.to, to.id)
    }
    
    func testRelatedEntities() {
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
        store.add(a)
        store.add(b)
        store.add(rel)
        let related = store.relatedEntities(from: a.id)
        XCTAssertEqual(related.count, 1)
        XCTAssertEqual(related.first?.id, b.id)
    }
}

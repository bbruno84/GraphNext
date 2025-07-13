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
        store = GraphStore(cacheEnabled: true)
    }
    
    override func tearDown() {
        store = nil
        super.tearDown()
    }
    
    func testAddEntity() {
        let entity = Entity(type: "Car", tags: ["test"])
        store.add(node: entity)
        let result = store.entity(id: entity.id)
        XCTAssertEqual(result?.id, entity.id)
        XCTAssertEqual(result?.type, "Car")
        XCTAssertTrue(result?.tags.contains("test") ?? false)
    }
    
    func testRemoveEntity() {
        let entity = Entity(type: "Driver")
        store.add(node: entity)
        store.remove(id: entity.id)
        XCTAssertNil(store.entity(id: entity.id))
    }
    
    func testEntitiesOfType() {
        let car = Entity(type: "Car")
        let bike = Entity(type: "Bike")
        store.add(node: car)
        store.add(node: bike)
        let cars = store.entities(ofType: "Car")
        XCTAssertEqual(cars.count, 1)
        XCTAssertEqual(cars.first?.id, car.id)
    }
    
    func testEntitiesTagged() {
        let tagged = Entity(type: "Car", tags: ["fast"])
        let untagged = Entity(type: "Car")
        store.add(node: tagged)
        store.add(node: untagged)
        let fastEntities = store.entities(tagged: "fast")
        XCTAssertEqual(fastEntities.count, 1)
        XCTAssertEqual(fastEntities.first?.id, tagged.id)
    }
    
    func testAddRelationship() {
        let from = Entity(type: "Start")
        let to = Entity(type: "End")
        let relationship = Relationship(type: "Link", from: from.id, to: to.id)
        store.add(node: from)
        store.add(node: to)
        store.add(node: relationship)
        let rels = store.relationships(from: from.id)
        XCTAssertEqual(rels.count, 1)
        XCTAssertEqual(rels.first?.to, to.id)
    }
    
    func testRelatedEntities() {
        let a = Entity(type: "A")
        let b = Entity(type: "B")
        let rel = Relationship(type: "connects", from: a.id, to: b.id)
        store.add(node: a)
        store.add(node: b)
        store.add(node: rel)
        let related = store.relatedEntities(from: a.id)
        XCTAssertEqual(related.count, 1)
        XCTAssertEqual(related.first?.id, b.id)
    }
}


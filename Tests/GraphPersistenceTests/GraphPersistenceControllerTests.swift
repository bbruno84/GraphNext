//
//  GraphPersistenceControllerTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import XCTest
import GraphNext
import GraphPersistence

final class GraphPersistenceControllerTests: XCTestCase {
    var sut: CoreDataGraphPersistenceController!

    override func setUp() {
        super.setUp()
        sut = CoreDataGraphPersistenceController(storeName: "GraphNext", inMemory: true)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Test Entity CRUD

    func testSaveAndLoadEntity() throws {
        let entity = Entity(
            id: UUID(),
            type: "TestEntity",
            tag: ["tag1"],
            group: ["group1"],
            indexed: ["key": "value"],
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            sharedWith: ["user1"],
            permissions: Permissions(users: ["user1": .read]),
            payload: ["test": .string("ok")]
        )

        try sut.save(node: entity)

        let loaded = try sut.loadNode(id: entity.id) as? Entity
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, entity.id)
        XCTAssertEqual(loaded?.type, "TestEntity")
        XCTAssertEqual(loaded?.indexed["key"], "value")
        XCTAssertEqual(loaded?.tag, ["tag1"])
        XCTAssertEqual(loaded?.group, ["group1"])
        XCTAssertEqual(loaded?.sharedWith, ["user1"])
    }

    // MARK: - Test Relationship CRUD

    func testSaveAndLoadRelationship() throws {
        let fromID = UUID()
        let toID = UUID()

        let relationship = Relationship(
            id: UUID(),
            type: "TestRelationship",
            tag: ["tag2"],
            group: ["group2"],
            indexed: ["rel": "yes"],
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            sharedWith: ["user2"],
            permissions: Permissions(users: ["user2": .write]),
            payload: ["rel": .bool(true)],
            from: fromID,
            to: toID
        )

        try sut.save(node: relationship)

        let loaded = try sut.loadNode(id: relationship.id) as? Relationship
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, relationship.id)
        XCTAssertEqual(loaded?.type, "TestRelationship")
        XCTAssertEqual(loaded?.from, fromID)
        XCTAssertEqual(loaded?.to, toID)
        XCTAssertEqual(loaded?.tag, ["tag2"])
        XCTAssertEqual(loaded?.group, ["group2"])
        XCTAssertEqual(loaded?.indexed["rel"], "yes")
        XCTAssertEqual(loaded?.sharedWith, ["user2"])
    }

    // MARK: - Test Delete

    func testDeleteRemovesNode() throws {
        let entity = Entity(
            id: UUID(),
            type: "ToDelete",
            tag: [],
            group: [],
            indexed: [:],
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: nil
        )

        try sut.save(node: entity)

        XCTAssertNotNil(try sut.loadNode(id: entity.id))

        try sut.deleteNode(id: entity.id)

        let deleted = try sut.loadNode(id: entity.id)
        XCTAssertNil(deleted)
    }
}


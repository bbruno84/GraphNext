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
        sut = CoreDataGraphPersistenceController(inMemory: true)
    }

    func testCRUD_Entity() throws {
        let entity = Entity(
            id: UUID(),
            type: "Test",
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
        XCTAssertEqual(loaded?.id, entity.id)
        XCTAssertEqual(loaded?.type, "Test")
        XCTAssertEqual(loaded?.indexed["key"], "value")

        try sut.deleteNode(id: entity.id)
        let deleted = try sut.loadNode(id: entity.id)
        XCTAssertNil(deleted)
    }

    func testCRUD_Relationship() throws {
        let fromID = UUID()
        let toID = UUID()

        let relationship = Relationship(
            id: UUID(),
            type: "Connected",
            tag: ["tag-rel"],
            group: ["group-rel"],
            indexed: ["relKey": "relValue"],
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            sharedWith: ["user1"],
            permissions: Permissions(users: ["user1": .write]),
            payload: ["relTest": .string("ok")],
            from: fromID,
            to: toID
        )

        try sut.save(node: relationship)

        let loaded = try sut.loadNode(id: relationship.id) as? Relationship
        XCTAssertEqual(loaded?.id, relationship.id)
        XCTAssertEqual(loaded?.type, "Connected")
        XCTAssertEqual(loaded?.from, fromID)
        XCTAssertEqual(loaded?.to, toID)
        XCTAssertEqual(loaded?.indexed["relKey"], "relValue")

        try sut.deleteNode(id: relationship.id)
        let deleted = try sut.loadNode(id: relationship.id)
        XCTAssertNil(deleted)
    }
}


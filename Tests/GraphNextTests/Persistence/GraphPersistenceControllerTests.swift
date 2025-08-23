//
//  GraphPersistenceControllerTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import XCTest
import GraphNext
import GRDB

final class GraphPersistenceControllerTests: XCTestCase {
    var sut: GraphPersistenceController!

    override func setUp() async throws {
            try await super.setUp()
        sut = try GRDBGraphPersistenceController(path: "TestDB", inMemory: true)
        }

        override func tearDown() async throws {
            sut = nil
            try await super.tearDown()
        }


    // MARK: - Test Entity CRUD

func testSaveAndLoadEntity() async throws {
    let entity = Entity(
        id: UUID(),
        type: "TestEntity",
        tag: ["tag1"],
        group: ["group1"],
        created: .init(by: "tester", at: .now),
        updated: nil,
        version: 1,
        sharedWith: ["user1"],
        permissions: Permissions(users: ["user1": .read]),
        payload: ["test": .string("ok")]
    )

    try await sut.saveEntity(entity)

    let loaded = try await sut.entity(id: entity.id)
    XCTAssertNotNil(loaded)
    XCTAssertEqual(loaded?.id, entity.id)
    XCTAssertEqual(loaded?.type, "TestEntity")
    XCTAssertEqual(loaded?.tag ?? [], ["tag1"])
    XCTAssertEqual(loaded?.group ?? [], ["group1"])
    XCTAssertEqual(loaded?.sharedWith ?? [], ["user1"])
}

    // MARK: - Test Relationship CRUD

    func testSaveAndLoadRelationship() async throws {
        let fromID = UUID()
        let toID = UUID()

        let relationship = Relationship(
            id: UUID(),
            type: "TestRelationship",
            tag: ["tag2"],
            group: ["group2"],
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            sharedWith: ["user2"],
            permissions: Permissions(users: ["user2": .write]),
            payload: ["rel": .bool(true)],
            from: fromID,
            to: toID
        )

        try await sut.saveRelationship(relationship)

        let loaded = try await sut.relationship(id: relationship.id)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, relationship.id)
        XCTAssertEqual(loaded?.type, "TestRelationship")
        XCTAssertEqual(loaded?.from, fromID)
        XCTAssertEqual(loaded?.to, toID)
        XCTAssertEqual(loaded?.tag ?? [], ["tag2"])
        XCTAssertEqual(loaded?.group ?? [], ["group2"])
        XCTAssertEqual(loaded?.sharedWith ?? [], ["user2"])
    }

    // MARK: - Test Delete

    func testDeleteRemovesNode() async throws {
        let entity = Entity(
            id: UUID(),
            type: "ToDelete",
            tag: [],
            group: [],
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: nil
        )

        try await sut.saveEntity(entity)

        let found = try await sut.entity(id: entity.id)
        XCTAssertNotNil(found)

        try await sut.deleteEntity(id: entity.id)

        let deleted = try await sut.entity(id: entity.id)
        XCTAssertNil(deleted)
    }
    
    // MARK: - Test Cascade Delete

    func testDeleteEntityAndAttachedRelationships_removesBoth() async throws {
        // Arrange
        let entity1 = Entity(id: UUID(), type: "A", created: .init(by: "test"))
        let entity2 = Entity(id: UUID(), type: "B", created: .init(by: "test"))

        let relationship = Relationship(
            id: UUID(),
            type: "rel",
            tag: [],
            group: [],
            created: .init(by: "test"),
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: nil,
            from: entity1.id,
            to: entity2.id
        )

        try await sut.saveEntity(entity1)
        try await sut.saveEntity(entity2)
        try await sut.saveRelationship(relationship)

        // Precondizione
        let loadedEntity = try await sut.entity(id: entity1.id)
        XCTAssertNotNil(loadedEntity)
        let relsBefore = try await sut.queryRelationships(matching: nil).filter { $0.from == entity1.id }
        XCTAssertEqual(relsBefore.count, 1)

        // Act
        try await sut.deleteEntityAndAttachedRelationships(id: entity1.id)

        // Assert
        let deletedEntity = try await sut.entity(id: entity1.id)
        XCTAssertNil(deletedEntity)
        let relsAfter = try await sut.queryRelationships(matching: nil).filter { $0.from == entity1.id }
        XCTAssertEqual(relsAfter.count, 0)
        let loadedEntity2 = try await sut.entity(id: entity2.id)
        XCTAssertNotNil(loadedEntity2) // entity2 deve rimanere
    }
    
    func testQueryEntitiesByType() async throws {
        let now = Date()
        let audit = AuditInfo(by: "test", at: now)

        let entity1 = Entity(
            id: UUID(),
            type: "sensor",
            tag: ["engine"],
            group: ["test"],
            created: audit,
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: ["temperature": .double(88.3)]
        )

        let entity2 = Entity(
            id: UUID(),
            type: "driver",
            tag: ["driver"],
            group: ["test"],
            created: audit,
            updated: nil,
            version: nil,
            sharedWith: [],
            permissions: nil,
            payload: ["name": .string("John")]
        )

        try await sut.saveEntities([entity1, entity2])

        let sensorEntities = try await sut.queryEntities(matching: "sensor")
        let sensorCount = sensorEntities.count
        let expectedSensorCount = 1
        XCTAssertEqual(sensorCount, expectedSensorCount)
        let firstSensorID = sensorEntities.first?.id
        let expectedSensorID = entity1.id
        XCTAssertEqual(firstSensorID, expectedSensorID)

        let allEntities = try await sut.queryEntities(matching: nil)
        let allCount = allEntities.count
        XCTAssertEqual(allCount, 2)
    }

}

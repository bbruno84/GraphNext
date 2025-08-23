//
//  GRDBRelationshipQueryTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//


import XCTest
@testable import GraphNext

final class GRDBRelationshipQueryTests: XCTestCase {

    var sut: GRDBGraphPersistenceController!

    override func setUpWithError() throws {
        sut = try GRDBGraphPersistenceController(path: "TestDB_Relationships", inMemory: true)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testQueryRelationshipsWherePayloadEquals() async throws {
        let rel = Relationship(
            id: UUID(),
            type: "rel_test",
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            payload: ["amount": .int(200)],
            from: UUID(),
            to: UUID()
        )
        try await sut.saveRelationship(rel)

        let matches = try await sut.queryRelationships(wherePayloadKey: "amount", equals: .int(200))
        XCTAssertTrue(matches.contains(where: { $0.id == rel.id }))
    }

    func testQueryRelationshipsWherePayloadGreaterThan() async throws {
        let rel = Relationship(
            id: UUID(),
            type: "rel_test",
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            payload: ["amount": .double(150.0)],
            from: UUID(),
            to: UUID()
        )

        try await sut.saveRelationship(rel)

        let matches = try await sut.queryRelationships(wherePayloadKey: "amount", greaterThan: .double(100.0))
        XCTAssertTrue(matches.contains(where: { $0.id == rel.id }))
    }

    func testQueryRelationshipsWherePayloadLessThan() async throws {
        let rel = Relationship(
            id: UUID(),
            type: "rel_test",
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            payload: ["amount": .int(30)],
            from: UUID(),
            to: UUID()
        )

        try await sut.saveRelationship(rel)

        let matches = try await sut.queryRelationships(wherePayloadKey: "amount", lessThan: .int(50))
        XCTAssertTrue(matches.contains(where: { $0.id == rel.id }))
    }

    func testQueryRelationshipsWherePayloadBetween() async throws {
        let rel = Relationship(
            id: UUID(),
            type: "rel_test",
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            payload: ["amount": .int(75)],
            from: UUID(),
            to: UUID()
        )

        try await sut.saveRelationship(rel)

        let matches = try await sut.queryRelationships(wherePayloadKey: "amount", between: .int(50), and: .int(100))
        XCTAssertTrue(matches.contains(where: { $0.id == rel.id }))
    }
}

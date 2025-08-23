//
//  GRDBGraphPersistenceConcurrencyTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//

import XCTest
@testable import GraphNext

final class GRDBGraphPersistenceConcurrencyTests: XCTestCase {

    var sut: GRDBGraphPersistenceController!

    override func setUpWithError() throws {
        sut = try GRDBGraphPersistenceController(path: "ConcurrencyTestDB", inMemory: true)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testConcurrentSaveAndLoadEntities() async throws {
        let expectation = XCTestExpectation(description: "Concurrent entity save/load")
        expectation.expectedFulfillmentCount = 10

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        let relationship = Relationship(
                            id: UUID(),
                            type: "RelType\(i)",
                            tag: ["tag\(i)"],
                            group: ["group\(i)"],
                            created: .init(by: "tester\(i)", at: .now),
                            updated: nil,
                            version: 1,
                            sharedWith: [],
                            permissions: nil,
                            payload: ["relIndex": .int(i)],
                            from: UUID(),
                            to: UUID()
                        )
                        try await self.sut.saveRelationship(relationship)
                        let loaded = try await self.sut.relationship(id: relationship.id)
                        XCTAssertEqual(loaded?.id, relationship.id)
                        expectation.fulfill()
                    } catch {
                        XCTFail("Task \(i) failed: \(error)")
                    }
                }
            }
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testConcurrentSaveAndLoadRelationships() async throws {
        let expectation = XCTestExpectation(description: "Concurrent relationship save/load")
        expectation.expectedFulfillmentCount = 10

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        let relationship = Relationship(
                            id: UUID(),
                            type: "RelType\(i)",
                            tag: ["tag\(i)"],
                            group: ["group\(i)"],
                            created: .init(by: "tester\(i)", at: .now),
                            updated: nil,
                            version: 1,
                            sharedWith: [],
                            permissions: nil,
                            payload: ["relIndex": .int(i)],
                            from: UUID(),
                            to: UUID()
                        )
                        try await self.sut.saveRelationship(relationship)
                        let loaded = try await self.sut.relationship(id: relationship.id)
                        XCTAssertEqual(loaded?.id, relationship.id)
                        expectation.fulfill()
                    } catch {
                        XCTFail("Task \(i) failed: \(error)")
                    }
                }
            }
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }
}

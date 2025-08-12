//
//  PushTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 03/08/25.
//

import XCTest
import CloudKit
@testable import GraphNext
@testable import GraphPersistence
@testable import GraphSyncEngine

final class PushTests: XCTestCase {
    var persistence: GraphPersistenceController!
    var store: GraphStore!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext", inMemory: true)
        store = GraphStore()
        sync = CloudKitSync(persistence: persistence, store: store)
    }

    override func tearDown() async throws {
        persistence = nil
        store = nil
        sync = nil
        try await super.tearDown()
    }

    func testPushWithSingleEntity() async throws {
        let entity = Entity(
            id: UUID(),
            type: "TestEntity",
            created: AuditInfo(by: "test", at: Date())
        )
        store.add(entity)

        do {
            try await sync.push()
        } catch {
            XCTFail("Push failed with error: \(error)")
        }
    }

    func testPushWithNoData() async throws {
        do {
            try await sync.push()
        } catch {
            XCTFail("Push should succeed with no data, but failed: \(error)")
        }
    }

    func testPushWithMultipleEntitiesAndRelationships() async throws {
        let entityA = Entity(id: UUID(), type: "A", created: AuditInfo(by: "test", at: Date()))
        let entityB = Entity(id: UUID(), type: "B", created: AuditInfo(by: "test", at: Date()))

        let relationship = Relationship(
            id: UUID(),
            type: "link",
            created: AuditInfo(by: "test", at: Date()),
            from: entityA.id,
            to: entityB.id
        )

        store.add(entityA)
        store.add(entityB)
        store.add(relationship)

        do {
            try await sync.push()
        } catch {
            XCTFail("Push of multiple nodes failed: \(error)")
        }
    }
}

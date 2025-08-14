//
//  SyncLogicTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 12/08/25.
//

import XCTest
import GraphNext
import GraphPersistence
@testable import GraphSyncEngine

final class SyncLogicTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext", inMemory: true)
        store = GraphStore()
        backend = MockRemoteBackend()
        sync = CloudKitSync(persistence: persistence, store: store, backend: backend)
    }

    func testPullPopulatesStoreFromBackend() async throws {
        let remote = Entity(id: UUID(), type: "Remote", created: .init(by: "r", at: .now))
        backend.entitiesStore = [remote]

        try await sync.pull()
        XCTAssertNotNil(store.entities[remote.id])
    }

    func testPushSendsLocalEntitiesToBackend() async throws {
        let e = Entity(id: UUID(), type: "Local", created: .init(by: "l", at: .now))
        store.add(e)

        try await sync.push()

        XCTAssertEqual(backend.savedEntitiesBatches.count, 1)
        XCTAssertEqual(backend.entitiesStore.count, 1)
        XCTAssertEqual(backend.entitiesStore.first?.id, e.id)
    }

    func testSyncCallsPullThenPush() async throws {
        let local = Entity(id: UUID(), type: "Local", created: .init(by: "l", at: .now))
        store.add(local)

        try await sync.sync()

        XCTAssertEqual(backend.fetchEntitiesCount, 1)
        XCTAssertEqual(backend.savedEntitiesBatches.count, 1)
    }
}

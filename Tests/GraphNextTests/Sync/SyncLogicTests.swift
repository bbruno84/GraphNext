//
//  SyncLogicTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 12/08/25.
//

import XCTest
@testable import GraphNext


final class SyncLogicTests: XCTestCase {
    var store: GraphStore!
    var persistence: GraphPersistenceController!
    var backend: MockRemoteBackend!
    var sync: CloudKitSync!

    override func setUp() async throws {
        try await super.setUp()
        persistence = CoreDataGraphPersistenceController(storeName: "GraphNext", inMemory: true)
        store = await GraphStore()
        backend = MockRemoteBackend()
        sync = await CloudKitSync(persistence: persistence, store: store, backend: backend)
    }

    func testPullPopulatesStoreFromBackend() async throws {
        let remote = Entity(id: UUID(), type: "Remote", created: .init(by: "r", at: .now))
        backend.entitiesStore = [remote]

        try await sync.pull()
        let result = await store.entity(id: remote.id)
        XCTAssertNotNil(result)
    }

    func testPushSendsLocalEntitiesToBackend() async throws {
        let e = Entity(id: UUID(), type: "Local", created: .init(by: "l", at: .now))
        await store.add(node: e, isRemote: false)

        try await sync.push()

        XCTAssertEqual(backend.savedEntitiesBatches.count, 1)
        XCTAssertEqual(backend.entitiesStore.count, 1)
        XCTAssertEqual(backend.entitiesStore.first?.id, e.id)
    }

    func testSyncCallsPullThenPush() async throws {
        let local = Entity(id: UUID(), type: "Local", created: .init(by: "l", at: .now))
        await store.add(node: local, isRemote: false)

        try await sync.sync()

        XCTAssertEqual(backend.fetchEntitiesCount, 1)
        XCTAssertEqual(backend.savedEntitiesBatches.count, 1)
    }
}

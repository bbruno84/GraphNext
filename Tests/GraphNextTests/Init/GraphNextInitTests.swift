//
//  GraphNextInitTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//


import XCTest
@testable import GraphNext

@MainActor final class GraphNextInitTests: XCTestCase {

    // MARK: - Mock engine

    @MainActor final class MockEngine: GraphSyncEngine {
        let id: String
        private(set) var calls: [String] = []

        init(id: String = "mock") { self.id = id }

        func pull() async throws {
            calls.append("pull")
        }

        func push() async throws {
            calls.append("push")
        }

        func sync() async throws {
            calls.append("sync")
        }

        func reset() async throws {
            calls.append("reset")
        }

        func callsSnapshot() -> [String] { calls }
    }

    // MARK: - Helpers

    private func waitForCalls(_ engine: MockEngine, expected: [String], timeout: TimeInterval = 2.0) async -> [String] {
        let start = Date()
        var got: [String] = []
        repeat {
            got = await MainActor.run { engine.callsSnapshot() }
            if got == expected { return got }
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        } while Date().timeIntervalSince(start) < timeout
        return got
    }

    // MARK: - Tests

    func testInitWithoutBackend_NoCrash() throws {
        // Usa il persistence reale in-memory (CoreDataGraphPersistenceController) dal target unico
        let cfg = GraphNextConfig(
            useNSCache: true,
            inMemoryStore: true,
            storeName: "Test_NoBackend",
            preloadFromPersistence: false,
            autoSyncOnLaunch: false,
            makePersistence: { name, mem in
                CoreDataGraphPersistenceController(storeName: name, inMemory: mem)
            },
            makeBackends: { _, _, _ in [] }
        )

        let g = try GraphNext(config: cfg)
        XCTAssertNotNil(g.store)
        XCTAssertNotNil(g.persistence)
        XCTAssertTrue(g.syncEngines.isEmpty)
    }

    func testInitWithBackend_AutoSyncPullThenPush() async throws {
        let engine = MockEngine()

        var cfg = GraphNextConfig(
            inMemoryStore: true,
            storeName: "Test_WithBackend",
            preloadFromPersistence: false,
            autoSyncOnLaunch: true,
            makePersistence: { name, mem in
                CoreDataGraphPersistenceController(storeName: name, inMemory: mem)
            },
            makeBackends: { _, _, _ in [engine] }
        )

        let g = try GraphNext(config: cfg)
        XCTAssertEqual(g.syncEngines.count, 1, "Dovrebbe essere presente un solo backend")

        let calls = await waitForCalls(engine, expected: ["pull", "push"])
        XCTAssertEqual(calls, ["pull", "push"], "L’ordine previsto è pull() → push() una sola volta")
    }

    func testPreloadFlag_NoCrash() throws {
        // Nota: se CoreDataGraphPersistenceController non adotta GraphPersistencePreloader,
        // il preload non verrà eseguito (cast fallisce) ma l'init non deve crashare.

        // preload OFF
        let cfgOff = GraphNextConfig(
            inMemoryStore: true,
            storeName: "Test_PreloadOff",
            preloadFromPersistence: false,
            makePersistence: { name, mem in
                CoreDataGraphPersistenceController(storeName: name, inMemory: mem)
            },
            makeBackends: { _, _, _ in [] }
        )
        _ = try GraphNext(config: cfgOff)

        // preload ON
        let cfgOn = GraphNextConfig(
            inMemoryStore: true,
            storeName: "Test_PreloadOn",
            preloadFromPersistence: true,
            makePersistence: { name, mem in
                CoreDataGraphPersistenceController(storeName: name, inMemory: mem)
            },
            makeBackends: { _, _, _ in [] }
        )
        _ = try GraphNext(config: cfgOn)
    }

    func testMultiInstance_IsolationAndAutoSync() async throws {
        let engineA = MockEngine(id: "engineA")
        let engineB = MockEngine(id: "engineB")

        let cfgA = GraphNextConfig(
            inMemoryStore: true,
            storeName: "Test_InstanceA",
            preloadFromPersistence: false,
            autoSyncOnLaunch: true,
            makePersistence: { name, mem in
                CoreDataGraphPersistenceController(storeName: name, inMemory: mem)
            },
            makeBackends: { _, _, _ in [engineA] }
        )

        let cfgB = GraphNextConfig(
            inMemoryStore: true,
            storeName: "Test_InstanceB",
            preloadFromPersistence: false,
            autoSyncOnLaunch: true,
            makePersistence: { name, mem in
                CoreDataGraphPersistenceController(storeName: name, inMemory: mem)
            },
            makeBackends: { _, _, _ in [engineB] }
        )

        let gA = try GraphNext(config: cfgA)
        let gB = try GraphNext(config: cfgB)

        XCTAssertEqual(gA.syncEngines.count, 1)
        XCTAssertEqual(gB.syncEngines.count, 1)
        XCTAssertTrue((gA.persistence as AnyObject) !== (gB.persistence as AnyObject), "Le due istanze devono avere persistence distinte")

        let callsA = await waitForCalls(engineA, expected: ["pull", "push"])
        let callsB = await waitForCalls(engineB, expected: ["pull", "push"])

        XCTAssertEqual(callsA, ["pull", "push"])
        XCTAssertEqual(callsB, ["pull", "push"])
    }
}

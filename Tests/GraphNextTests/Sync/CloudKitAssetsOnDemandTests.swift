//
//  CloudKitAssetsOnDemandTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/25.
//


import XCTest
import Combine
import CloudKit
@testable import GraphNext

final class CloudKitAssetsOnDemandTests: XCTestCase {

    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("GN_Assets_CKFetch_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        AssetStorageProvider.shared.setStorage(try FileAssetStorage(baseDirectory: dir))
    }

    override func tearDown() {
        CloudKitTestHooks.fetchAssetRecord = nil
        cancellables.removeAll()
    }

    func testFetchAssetIfNeeded_UsesHookAndSavesToStorage_AndNotifiesStore() async throws {
        // Prepara un file temporaneo che simula il contenuto di CKAsset
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let tempFile = tempDir.appendingPathComponent("ckasset-\(UUID().uuidString).bin")
        let payload = Data([0x41, 0x42, 0x43, 0x44]) // "ABCD"
        try payload.write(to: tempFile)

        let assetId = UUID()
        CloudKitTestHooks.fetchAssetRecord = { requested in
            guard requested == assetId else { return nil }
            let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
            let recordID = CKRecord.ID(recordName: requested.uuidString, zoneID: zoneID)
            let rec = CKRecord(recordType: "Entity", recordID: recordID)
            rec["file"] = CKAsset(fileURL: tempFile)
            return rec
        }

        let store = await GraphStore()
        let entity = Entity(
            id: assetId,
            type: "asset",
            tag: [],
            group: [],
            created: .init(by: "test", at: .now),
            updated: nil,
            version: 1,
            sharedWith: [],
            permissions: nil,
            payload: [
                "mimeType": .string("application/octet-stream"),
                "fileName": .string("hook.bin"),
                "length": .int(payload.count),
                "sha256": .string(payload.sha256Hex())
            ]
        )
        await store.add(node: entity, isRemote: false)

        let exp = expectation(description: "store notified about asset readiness")
        await store.changeFeed.sink { change in
            if case let .update(node, isRemote) = change, let e = node as? Entity, e.id == assetId {
                XCTAssertTrue(isRemote)
                exp.fulfill()
            }
        }.store(in: &cancellables)

        let config = CloudKitSyncConfig()
        let dummyPersistence = DummyPersistence()
        let sync = await CloudKitSync(persistence: dummyPersistence, store: store, backend: MockRemoteBackend(), configuration: config)

        try await sync.fetchAssetIfNeededAndNotify(assetId: assetId)

        let url = try AssetStorageProvider.shared.storage.urlIfPresent(assetId: assetId)
        XCTAssertNotNil(url)

        await fulfillment(of: [exp], timeout: 1.0)
    }
}

// MARK: - Dummy Persistence

final class DummyPersistence: GraphPersistenceController {

    func saveEntity(_ entity: Entity) async throws {}
    func entity(id: UUID) async throws -> Entity? { nil }
    func deleteEntity(id: UUID) async throws {}
    func deleteEntityAndAttachedRelationships(id: UUID) async throws {}
    func saveEntities(_ entities: [Entity]) async throws {}
    func deleteEntities(_ ids: [UUID]) async throws {}
    func saveRelationship(_ relationship: Relationship) async throws {}
    func relationship(id: UUID) async throws -> Relationship? { nil }
    func deleteRelationship(id: UUID) async throws {}
    func saveRelationships(_ relationships: [Relationship]) async throws {}
    func deleteRelationships(_ ids: [UUID]) async throws {}
    func allEntities() async throws -> [Entity] { [] }
    func allRelationships() async throws -> [Relationship] { [] }
    func reset() async throws {}

    func queryEntities(matching type: String?) async throws -> [Entity] {
        return []
    }

    func queryRelationships(matching type: String?) async throws -> [Relationship] {
        return []
    }
}

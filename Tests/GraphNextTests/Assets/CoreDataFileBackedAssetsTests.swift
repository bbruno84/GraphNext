//
//  CoreDataFileBackedAssetsTests.swift
//  GraphNextTests
//
//  Created by Regia GraphNext on 24/08/2025.
//

import XCTest
@testable import GraphNext

final class CoreDataFileBackedAssetsTests: XCTestCase {

    private func makeController() throws -> CoreDataGraphPersistenceController {
        // Usa lo store in-memory come nel tuo controller
        return CoreDataGraphPersistenceController(storeName: "GN_Test_CD", inMemory: true)
    }

    private func isolateStorage() throws {
        // Isola l’AssetStorage in una cartella temp per non inquinare altri test
        let assetsDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("GN_Assets_CD_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        try AssetStorageProvider.shared.setStorage(try FileAssetStorage(baseDirectory: assetsDir))
    }

    func testCreateAttachAndRoundTrip_CoreData() async throws {
        try isolateStorage()
        let controller = try makeController()

        // Owner entity
        let owner = Entity(
            id: UUID(),
            type: "doc",
            tag: [],
            group: [],
            created: .init(by: "test", at: .now),
            updated: nil,
            version: 1,
            sharedWith: [],
            permissions: nil,
            payload: [:]
        )
        try await controller.saveEntity(owner)

        // Dati finti (header PDF)
        let data = Data([0x25, 0x50, 0x44, 0x46])
        let asset = try await controller.createAssetAndAttach(
            data: data,
            mimeType: "application/pdf",
            fileName: "cd-sample.pdf",
            attachTo: owner.id
        )

        // URL presente?
        let url = try await controller.assetURLIfPresent(assetId: asset.id)
        XCTAssertNotNil(url, "URL locale dovrebbe esistere dopo il salvataggio")

        // Load bytes e verifica
        let loaded = try await controller.loadAssetData(assetId: asset.id)
        XCTAssertEqual(loaded, data)

        // Verify checksum
        let ok = try AssetStorageProvider.shared.storage.verifyChecksum(assetId: asset.id)
        XCTAssertTrue(ok, "Checksum dovrebbe combaciare")

        // Delete SOLO file (non entity)
        try await controller.deleteAsset(assetId: asset.id)
        let afterDeleteURL = try await controller.assetURLIfPresent(assetId: asset.id)
        XCTAssertNil(afterDeleteURL, "URL dovrebbe essere nil dopo la delete del file")
    }

    func testCascadeDeleteAlsoRemovesFile_CoreData() async throws {
        try isolateStorage()
        let controller = try makeController()

        let asset = try await controller.createAssetAndAttach(
            data: Data("to be deleted".utf8),
            mimeType: "text/plain",
            fileName: "delete.txt",
            attachTo: UUID()
        )

        // Cancella l'entity asset → il file deve sparire grazie al best‑effort nel controller
        try await controller.deleteEntity(id: asset.id)
        let urlAfterDelete = try await controller.assetURLIfPresent(assetId: asset.id)
        XCTAssertNil(urlAfterDelete, "Ci si aspetta che il file asset sia stato rimosso dallo storage locale")
    }

    func testSaveAssetDataUpdatesContentAndMetadata_CoreData() async throws {
        try isolateStorage()
        let controller = try makeController()

        // Crea asset "vuoto" salvando direttamente i dati e poi costruendo l'entity.
        let assetId = UUID()
        let bytesV1 = Data("v1".utf8)
        _ = try await controller.saveAssetData(assetId: assetId, data: bytesV1, mimeType: "text/plain", fileName: "note.txt")

        // Crea l’Entity(type:"asset") con metadati coerenti
        let assetEntity = Entity(
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
                "mimeType": .string("text/plain"),
                "fileName": .string("note.txt"),
                "length": .int(bytesV1.count),
                "sha256": .string(bytesV1.sha256Hex())
            ]
        )
        try await controller.saveEntity(assetEntity)

        // Aggiorna i bytes
        let bytesV2 = Data("v2-updated".utf8)
        let meta = try await controller.saveAssetData(assetId: assetId, data: bytesV2, mimeType: "text/plain", fileName: "note.txt")
        XCTAssertEqual(meta.length, bytesV2.count)

        // Load: deve riflettere la V2
        let loaded = try await controller.loadAssetData(assetId: assetId)
        XCTAssertEqual(loaded, bytesV2)

        // URL presente
        let finalURL = try await controller.assetURLIfPresent(assetId: assetId)
        XCTAssertNotNil(finalURL)
    }
}

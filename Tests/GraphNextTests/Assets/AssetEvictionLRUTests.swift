// Tests/GraphNextTests/Assets/AssetEvictionLRUTests.swift
//
//  AssetEvictionLRUTests.swift
//  GraphNextTests
//
//  Created by Regia GraphNext on 25/08/2025.
//

import XCTest
@testable import GraphNext

final class AssetEvictionLRUTests: XCTestCase {

    private func makeIsolatedStorage(quotaBytes: Int) throws -> FileAssetStorage {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("GN_Assets_LRU_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let storage = try FileAssetStorage(baseDirectory: base, quotaBytes: quotaBytes)
        // setStorage NON lancia: niente `try` qui
        AssetStorageProvider.shared.setStorage(storage)
        return storage
    }

    func testEvictsLeastRecentlyUsedWhenQuotaExceeded() throws {
        // Quota molto piccola: 10 byte
        let storage = try makeIsolatedStorage(quotaBytes: 10)

        // Tre asset: 6 + 4 + 4 = 14 > 10 → deve cadere il più vecchio
        let a1 = UUID(), a2 = UUID(), a3 = UUID()
        let d1 = Data("AAAAAA".utf8) // 6
        let d2 = Data("BBBB".utf8)   // 4
        let d3 = Data("CCCC".utf8)   // 4

        _ = try storage.save(data: d1, for: a1, meta: .init(length: d1.count, sha256: d1.sha256Hex(), mimeType: "text/plain", fileName: "a1"))
        _ = try storage.save(data: d2, for: a2, meta: .init(length: d2.count, sha256: d2.sha256Hex(), mimeType: "text/plain", fileName: "a2"))

        // Tocchiamo a2 per renderlo più “recente”
        _ = try storage.urlIfPresent(assetId: a2)

        // Salvataggio che supera quota → evict LRU (a1)
        _ = try storage.save(data: d3, for: a3, meta: .init(length: d3.count, sha256: d3.sha256Hex(), mimeType: "text/plain", fileName: "a3"))

        // a1 dovrebbe essere stato rimosso
        XCTAssertNil(try storage.urlIfPresent(assetId: a1))
        // a2 e a3 presenti
        XCTAssertNotNil(try storage.urlIfPresent(assetId: a2))
        XCTAssertNotNil(try storage.urlIfPresent(assetId: a3))
    }

    func testAccessRefreshesLRU() throws {
        let storage = try makeIsolatedStorage(quotaBytes: 10)

        let a1 = UUID(), a2 = UUID()
        let d1 = Data("AAAA".utf8)   // 4
        let d2 = Data("BBBBBB".utf8) // 6 → totale 10, in quota

        _ = try storage.save(data: d1, for: a1, meta: .init(length: d1.count, sha256: d1.sha256Hex(), mimeType: "text/plain", fileName: "a1"))
        _ = try storage.save(data: d2, for: a2, meta: .init(length: d2.count, sha256: d2.sha256Hex(), mimeType: "text/plain", fileName: "a2"))

        // Tocchiamo a1 (diventa il più “recente”)
        _ = try storage.urlIfPresent(assetId: a1)

        // Aggiungiamo un terzo asset da 4 → 14 > 10: evict quello meno recente (a2)
        let a3 = UUID()
        let d3 = Data("CCCC".utf8)   // 4
        _ = try storage.save(data: d3, for: a3, meta: .init(length: d3.count, sha256: d3.sha256Hex(), mimeType: "text/plain", fileName: "a3"))

        // a1 deve restare (è stato toccato)
        XCTAssertNotNil(try storage.urlIfPresent(assetId: a1))
        // a2 deve essere rimosso
        XCTAssertNil(try storage.urlIfPresent(assetId: a2))
        // a3 presente
        XCTAssertNotNil(try storage.urlIfPresent(assetId: a3))
    }
}

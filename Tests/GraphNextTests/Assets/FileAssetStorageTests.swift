//
//  FileAssetStorageTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/25.
//


//
//  FileAssetStorageTests.swift
//  GraphNextTests
//
//  Created by Regia GraphNext on 24/08/2025.
//

import XCTest
@testable import GraphNext

final class FileAssetStorageTests: XCTestCase {

    private func makeTempDir() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("GN_Assets_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    func testRoundTrip_Save_Open_Verify_Remove() throws {
        let tmp = try makeTempDir()
        let storage = try FileAssetStorage(baseDirectory: tmp)

        // piccoli sample bytes (PNG header + qualche byte)
        let bytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x11, 0x22, 0x33])
        let sha = bytes.sha256Hex()
        let meta = AssetMetadata(length: bytes.count, sha256: sha, mimeType: "image/png", fileName: "sample.png")
        let assetId = UUID()

        // save
        let url = try storage.save(data: bytes, for: assetId, meta: meta)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        // exists + urlIfPresent
        XCTAssertTrue(try storage.exists(assetId: assetId))
        XCTAssertEqual(try storage.urlIfPresent(assetId: assetId)?.path, url.path)

        // openRead + verifyChecksum
        let stream = try XCTUnwrap(try storage.openRead(assetId: assetId))
        stream.open()
        var readback = Data()
        var buffer = [UInt8](repeating: 0, count: 64)
        while stream.hasBytesAvailable {
            let n = stream.read(&buffer, maxLength: buffer.count)
            if n <= 0 { break }
            readback.append(buffer, count: n)
        }
        stream.close()
        XCTAssertEqual(readback, bytes)
        XCTAssertTrue(try storage.verifyChecksum(assetId: assetId))

        // remove (content dedup safe: nessun altro indice punta allo stesso sha)
        try storage.remove(assetId: assetId)
        XCTAssertFalse(try storage.exists(assetId: assetId))
    }

    func testChecksumMismatchDetection() throws {
        let tmp = try makeTempDir()
        let storage = try FileAssetStorage(baseDirectory: tmp)

        let bytes = Data([0x01, 0x02, 0x03, 0x04])
        let wrongMeta = AssetMetadata(length: bytes.count, sha256: "deadbeef", mimeType: "application/octet-stream")
        let assetId = UUID()

        XCTAssertThrowsError(try storage.save(data: bytes, for: assetId, meta: wrongMeta)) { error in
            guard case AssetStorageError.checksumMismatch = error else {
                return XCTFail("Expected checksumMismatch, got \(error)")
            }
        }
    }

    func testDeduplicationBySHA() throws {
        let tmp = try makeTempDir()
        let storage = try FileAssetStorage(baseDirectory: tmp)

        let bytes = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let sha = bytes.sha256Hex()
        let meta = AssetMetadata(length: bytes.count, sha256: sha, mimeType: "application/octet-stream")
        let id1 = UUID()
        let id2 = UUID()

        let url1 = try storage.save(data: bytes, for: id1, meta: meta)
        let url2 = try storage.save(data: bytes, for: id2, meta: meta)
        XCTAssertEqual(url1.path, url2.path, "Contenuto deve essere deduplicato per SHA")

        // Rimuovi id1 ma lascia id2: il contenuto non deve sparire
        try storage.remove(assetId: id1)
        XCTAssertTrue(try storage.exists(assetId: id2))
        XCTAssertNotNil(try storage.urlIfPresent(assetId: id2))
    }
}

//
//  AssetService.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/25.
//


import Foundation

public enum AssetService {

    @inline(__always)
    private static var storage: AssetStorage { AssetStorageProvider.shared.storage }

    @discardableResult
    public static func save(assetId: UUID, data: Data, mimeType: String, fileName: String? = nil) throws -> AssetMetadata {
        let sha = data.sha256Hex()
        let meta = AssetMetadata(length: data.count, sha256: sha, mimeType: mimeType, fileName: fileName)
        _ = try storage.save(data: data, for: assetId, meta: meta)
        return meta
    }

    public static func load(assetId: UUID) throws -> Data {
        guard let stream = try storage.openRead(assetId: assetId) else {
            throw NSError(domain: "GraphNext", code: 404, userInfo: [NSLocalizedDescriptionKey: "Asset not found locally"])
        }
        stream.open(); defer { stream.close() }
        var out = Data()
        var buf = [UInt8](repeating: 0, count: 256*1024)
        while stream.hasBytesAvailable {
            let n = stream.read(&buf, maxLength: buf.count)
            if n <= 0 { break }
            out.append(buf, count: n)
        }
        return out
    }

    public static func open(assetId: UUID) throws -> InputStream? {
        try storage.openRead(assetId: assetId)
    }

    public static func urlIfPresent(assetId: UUID) throws -> URL? {
        try storage.urlIfPresent(assetId: assetId)
    }

    public static func delete(assetId: UUID) throws {
        try storage.remove(assetId: assetId)
    }

    public static func verify(assetId: UUID) throws -> Bool {
        try storage.verifyChecksum(assetId: assetId)
    }
}

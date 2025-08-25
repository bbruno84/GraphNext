//
//  CloudKitSync+Assets.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/2025.
//

import Foundation
import CloudKit

extension CloudKitSync {

    // MARK: - Public API

    public func fetchAssetIfNeeded(assetId: UUID) async throws {
        // 1) Se il file è già presente, no-op
        if let _ = try? AssetStorageProvider.shared.storage.urlIfPresent(assetId: assetId) {
            return
        }

        // 2) Test hook: bypass CloudKit se impostato
        if let hook = CloudKitTestHooks.fetchAssetRecord, let record = hook(assetId) {
            try await Self._saveAssetFromRecord(record, assetId: assetId)
            return
        }

        // 3) Fetch reale da CloudKit (solo chiave "file")
        let (db, zoneID) = makeDatabaseAndZone()
        let recordID = CKRecord.ID(recordName: assetId.uuidString, zoneID: zoneID)

        let record: CKRecord = try await withCheckedThrowingContinuation { cont in
            let op = CKFetchRecordsOperation(recordIDs: [recordID])
            op.desiredKeys = ["file"]

            var fetched: CKRecord?
            op.perRecordResultBlock = { id, result in
                if case let .success(rec) = result, id == recordID {
                    fetched = rec
                }
            }

            op.fetchRecordsResultBlock = { result in
                switch result {
                case .success:
                    if let rec = fetched {
                        cont.resume(returning: rec)
                    } else {
                        cont.resume(throwing: NSError(
                            domain: "GraphNext.CloudKit",
                            code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "CKRecord not found for asset \(assetId)"]
                        ))
                    }
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }

            db.add(op)
        }

        try await Self._saveAssetFromRecord(record, assetId: assetId)
    }

    public func fetchAssetIfNeeded(assetId: UUID, store: GraphStore?) async throws {
        try await fetchAssetIfNeeded(assetId: assetId)
        guard let store = store else { return }
        await MainActor.run {
            store.notifyAssetReady(assetId)
        }
    }

    public func fetchAssetIfNeededAndNotify(assetId: UUID) async throws {
        try await fetchAssetIfNeeded(assetId: assetId, store: self.store)
    }

    // MARK: - Helpers

    private static func _saveAssetFromRecord(_ record: CKRecord, assetId: UUID) async throws {
        guard let ckAsset = record["file"] as? CKAsset, let remoteURL = ckAsset.fileURL else {
            throw NSError(
                domain: "GraphNext.CloudKit",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No CKAsset 'file' for asset \(assetId)"]
            )
        }

        guard let stream = InputStream(url: remoteURL) else {
            throw NSError(
                domain: "GraphNext.CloudKit",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Unable to open stream for CKAsset file URL"]
            )
        }

        var bytes = Data()
        bytes.reserveCapacity(256 * 1024)
        stream.open()
        defer { stream.close() }

        var buffer = [UInt8](repeating: 0, count: 256 * 1024)
        while stream.hasBytesAvailable {
            let n = stream.read(&buffer, maxLength: buffer.count)
            if n < 0 {
                throw stream.streamError ?? NSError(
                    domain: "GraphNext.CloudKit",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Stream read error"]
                )
            }
            if n == 0 { break }
            bytes.append(buffer, count: n)
        }

        let sha = bytes.sha256Hex()
        let meta = AssetMetadata(length: bytes.count, sha256: sha, mimeType: "application/octet-stream", fileName: nil)
        _ = try AssetStorageProvider.shared.storage.save(data: bytes, for: assetId, meta: meta)
    }

    private func makeDatabaseAndZone() -> (CKDatabase, CKRecordZone.ID) {
        let container: CKContainer = {
            if let id = configuration.containerIdentifier {
                return CKContainer(identifier: id)
            } else {
                return CKContainer.default()
            }
        }()
        let zoneID = CKRecordZone.ID(zoneName: configuration.zoneName, ownerName: CKCurrentUserDefaultName)
        return (container.privateCloudDatabase, zoneID)
    }
}

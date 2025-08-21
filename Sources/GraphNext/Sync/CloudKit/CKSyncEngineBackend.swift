//
//  CKSyncEngineBackend.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/08/25.
//

import Foundation
import CloudKit

actor SyncState {
    var pendingRecords: [CKRecord.ID: CKRecord] = [:]
    var receivedBuffer: [CKRecord] = []
    var deletedEntityIDs: [UUID] = []
    var deletedRelationshipIDs: [UUID] = []

    func appendReceived(_ record: CKRecord) {
        receivedBuffer.append(record)
    }

    func snapshotReceived() -> [CKRecord] {
        receivedBuffer
    }

    func drainReceived() -> [CKRecord] {
        let snapshot = receivedBuffer
        receivedBuffer.removeAll()
        return snapshot
    }

    func addPending(_ record: CKRecord) {
        pendingRecords[record.recordID] = record
    }

    func removePending(_ recordID: CKRecord.ID) {
        pendingRecords.removeValue(forKey: recordID)
    }

    func recordProvider(for id: CKRecord.ID) -> CKRecord? {
        pendingRecords[id]
    }

    func pendingIsEmpty() -> Bool {
        pendingRecords.isEmpty
    }

    func appendDeletedEntityID(_ id: UUID) { deletedEntityIDs.append(id) }
    func appendDeletedRelationshipID(_ id: UUID) { deletedRelationshipIDs.append(id) }
    func drainDeletedEntityIDs() -> [UUID] { let ids = deletedEntityIDs; deletedEntityIDs.removeAll(); return ids }
    func drainDeletedRelationshipIDs() -> [UUID] { let ids = deletedRelationshipIDs; deletedRelationshipIDs.removeAll(); return ids }
}

@MainActor private final class _CKSEDelegateProxy: NSObject, CKSyncEngineDelegate {
    weak var target: CKSyncEngineDelegate?

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        await target?.handleEvent(event, syncEngine: syncEngine)
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        await target?.nextRecordZoneChangeBatch(context, syncEngine: syncEngine)
    }
}

@MainActor final class CKSyncEngineBackend: NSObject, RemoteSyncBackend, CKSyncEngineDelegate {
    private let engine: CKSyncEngine
    private let zoneID: CKRecordZone.ID
    private let database: CKDatabase
    private let stateStore: CloudKitSyncConfig.StateStore
    private let state = SyncState()
    private let delegateProxy: _CKSEDelegateProxy
    private let subscriptionID: String
    private let retryMaxAttempts: Int
    private let retryBaseDelaySeconds: Double

    init(container: CKContainer,
         zoneID: CKRecordZone.ID,
         stateStore: CloudKitSyncConfig.StateStore = .userDefaults(suiteName: "CKSE.GraphNextState"),
         subscriptionID: String,
         retryMaxAttempts: Int,
         retryBaseDelaySeconds: Double) {

        self.zoneID = zoneID
        self.stateStore = stateStore

        let proxy = _CKSEDelegateProxy()
        self.delegateProxy = proxy

        let db = container.privateCloudDatabase
        self.database = db
        var savedState: CKSyncEngine.State.Serialization? = nil

        switch stateStore {
        case .userDefaults(let suite):
            let defaults = UserDefaults(suiteName: suite) ?? .standard
            if let data = defaults.data(forKey: "CKSE.GraphNextState") {
                if let state = try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data) {
                    savedState = state
                }
            }

        case .fileSystem(let path):
            let url = URL(fileURLWithPath: path, isDirectory: false)
            if let data = try? Data(contentsOf: url) {
                if let state = try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data) {
                    savedState = state
                }
            }
        }

        let config = CKSyncEngine.Configuration(
            database: db,
            stateSerialization: savedState,
            delegate: proxy
        )
        self.engine = CKSyncEngine(config)
        self.subscriptionID = subscriptionID
        self.retryMaxAttempts = retryMaxAttempts
        self.retryBaseDelaySeconds = retryBaseDelaySeconds

        super.init()

        proxy.target = self
    }

    // MARK: - Retry / Backoff helper
    /// Esegue un'operazione con retry esponenziale per errori CloudKit transitori.
    private func withRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        for attempt in 1...retryMaxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if let ckErr = error as? CKError {
                    let retryable: Set<CKError.Code> = [
                        .networkUnavailable, .networkFailure,
                        .serviceUnavailable, .requestRateLimited,
                        .zoneBusy,
                        .serverRejectedRequest
                    ]
                    if retryable.contains(ckErr.code), attempt < retryMaxAttempts {
                        let delay = retryBaseDelaySeconds * pow(2, Double(attempt - 1))
                        let ns = UInt64(delay * 1_000_000_000)
                        try? await Task.sleep(nanoseconds: ns)
                        continue
                    }
                }
                throw error
            }
        }
        throw lastError ?? NSError(domain: "CKSyncEngineBackend.withRetry", code: -1)
    }

    // MARK: - CKSyncEngineDelegate
    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .fetchedRecordZoneChanges(let changes):
            for modification in changes.modifications {
                await self.state.appendReceived(modification.record)
            }
            for deletion in changes.deletions {
                let recID = deletion.recordID
                switch deletion.recordType {
                case "Entity":
                    if let uuid = UUID(uuidString: recID.recordName) {
                        await self.state.appendDeletedEntityID(uuid)
                    }
                case "Relationship":
                    if let uuid = UUID(uuidString: recID.recordName) {
                        await self.state.appendDeletedRelationshipID(uuid)
                    }
                default: break
                }
            }
        case .sentRecordZoneChanges(let result):
            for saved in result.savedRecords {
                await self.state.removePending(saved.recordID)
            }
            // In caso di conflitti, "remote wins": non reaccodiamo i record locali
        case .stateUpdate(let update):
            // Persist the new engine state so we can provide it on next launch
            if let data = try? JSONEncoder().encode(update.stateSerialization) {
                switch self.stateStore {
                case .userDefaults(let suite):
                    let defaults = UserDefaults(suiteName: suite) ?? .standard
                    defaults.set(data, forKey: "CKSE.GraphNextState")
                case .fileSystem(let path):
                    let url = URL(fileURLWithPath: path, isDirectory: false)
                    try? data.write(to: url)
                }
            }
        default:
            break
        }
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {

        let pending = syncEngine.state.pendingRecordZoneChanges

        guard !pending.isEmpty else { return nil }

        return await CKSyncEngine.RecordZoneChangeBatch(
            pendingChanges: pending,
            recordProvider: { [weak self] recordID in
                if let self = self,
                   let rec = await self.state.recordProvider(for: recordID) {
                    return rec
                }
                // Fallback: record minimo con lo stesso ID
                return CKRecord(recordType: "Entity", recordID: recordID)
            }
        )
    }

    // MARK: - RemoteSyncBackend

    func prepareDeltaFetch() async throws {
        // Pulisce eventuali record precedenti
        _ = await state.drainReceived()
        _ = await state.drainDeletedEntityIDs()
        _ = await state.drainDeletedRelationshipIDs()
        // Richiede a CKSyncEngine di scaricare le modifiche dalla zona
        try await withRetry {
            try await self.engine.fetchChanges(.init())
        }
    }

    func fetchEntities() async throws -> [Entity] {
        let records = await state.snapshotReceived()
        return records
            .filter { $0.recordType == "Entity" }
            .compactMap(Entity.init(from:))
    }

    func fetchRelationships() async throws -> [Relationship] {
        let records = await state.snapshotReceived()
        return records
            .filter { $0.recordType == "Relationship" }
            .compactMap(Relationship.init(from:))
    }

    func save(entities: [Entity]) async throws {
        let records = entities.map { $0.asCKRecord() }
        for rec in records {
            await state.addPending(rec)
            engine.state.add(
                pendingRecordZoneChanges: [ .saveRecord(rec.recordID) ]
            )
        }
        try await withRetry {
            try await self.engine.sendChanges()
        }
    }

    func save(relationships: [Relationship]) async throws {
        let records = relationships.map { $0.asCKRecord() }
        for rec in records {
            await state.addPending(rec)
            engine.state.add(
                pendingRecordZoneChanges: [ .saveRecord(rec.recordID) ]
            )
        }
        try await withRetry {
            try await self.engine.sendChanges()
        }
    }

    func resetRemote() async throws { /* opzionale */ }
    
    // MARK: - Subscriptions (push / silent notifications)
    func subscribeToRemoteChanges() async throws {
        // Upsert idempotente di una subscription a livello di database.
        let subscriptionID = self.subscriptionID

        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true // silent push

        let dbSub = CKDatabaseSubscription(subscriptionID: subscriptionID)
        dbSub.notificationInfo = info

        let op = CKModifySubscriptionsOperation(
            subscriptionsToSave: [dbSub],
            subscriptionIDsToDelete: []
        )

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            op.modifySubscriptionsResultBlock = { result in
                switch result {
                case .success:
                    cont.resume()
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            self.database.add(op)
        }
    }

    func fetchDeletedEntityIDs() async throws -> [UUID] {
        return await state.drainDeletedEntityIDs()
    }

    func fetchDeletedRelationshipIDs() async throws -> [UUID] {
        return await state.drainDeletedRelationshipIDs()
    }
}

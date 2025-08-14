//
//  CKSyncEngineBackend.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/08/25.
//

import Foundation
import CloudKit
import GraphNext

actor SyncState {
    var pendingRecords: [CKRecord.ID: CKRecord] = [:]
    var receivedBuffer: [CKRecord] = []

    func appendReceived(_ record: CKRecord) {
        receivedBuffer.append(record)
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
}

final class CKSyncEngineBackend: NSObject, RemoteSyncBackend, CKSyncEngineDelegate {
    private var engine: CKSyncEngine!
    private let zoneID: CKRecordZone.ID
    private let stateStore: CloudKitSyncConfig.StateStore
    private let state = SyncState()

    init(container: CKContainer,
         zoneID: CKRecordZone.ID,
         stateStore: CloudKitSyncConfig.StateStore = .userDefaults(suiteName: "CKSE.GraphNextState")) {

        self.zoneID = zoneID
        self.stateStore = stateStore

        let db = container.privateCloudDatabase
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

        super.init()

        let config = CKSyncEngine.Configuration(
            database: db,
            stateSerialization: savedState,
            delegate: self
        )
        self.engine = CKSyncEngine(config)
    }

    // MARK: - CKSyncEngineDelegate
    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .fetchedRecordZoneChanges(let changes):
            for modification in changes.modifications {
                await self.state.appendReceived(modification.record)
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

    func fetchEntities() async throws -> [Entity] {
        _ = await state.drainReceived() // ensure empty before fetch
        try await engine.fetchChanges(.init())
        let records = await state.drainReceived()
        return records
            .filter { $0.recordType == "Entity" }
            .compactMap(Entity.init(from:))
    }

    func fetchRelationships() async throws -> [Relationship] {
        let records = await state.drainReceived()
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
        try await engine.sendChanges()
    }

    func save(relationships: [Relationship]) async throws {
        let records = relationships.map { $0.asCKRecord() }
        for rec in records {
            await state.addPending(rec)
            engine.state.add(
                pendingRecordZoneChanges: [ .saveRecord(rec.recordID) ]
            )
        }
        try await engine.sendChanges()
    }

    func resetRemote() async throws { /* opzionale */ }
}

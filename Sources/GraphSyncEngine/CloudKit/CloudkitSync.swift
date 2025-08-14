//
//  CloudkitSync.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation
import CloudKit
import GraphPersistence
import GraphNext

public final class CloudKitSync: GraphSyncEngine {
    internal let persistence: GraphPersistenceController
    internal let store: GraphStore
    internal let backend: RemoteSyncBackend
    internal(set) public var isSyncing: Bool = false

    // Config conservata per debug/telemetria o subscribeOnInit
    public let configuration: CloudKitSyncConfig

    /// Iniezione standard: CKSyncEngineBackend costruito da config.
    public init(
        persistence: GraphPersistenceController,
        store: GraphStore,
        configuration: CloudKitSyncConfig,
        container: CKContainer
    ) {
        self.persistence = persistence
        self.store = store
        self.configuration = configuration

        // Costruzione del backend reale basato su CKSyncEngine e sulla zone configurata.
        let zoneID = CKRecordZone.ID(zoneName: configuration.zoneName)
        self.backend = CKSyncEngineBackend(container: container, zoneID: zoneID, stateStore: configuration.stateStore)

        if configuration.subscribeOnInit {
            // non lancia: puoi farlo async separato se preferisci
            Task { try? await self.subscribeToRemoteChanges() }
        }
    }

    /// Iniezione alternativa per test: backend mock o custom.
    init(
        persistence: GraphPersistenceController,
        store: GraphStore,
        backend: RemoteSyncBackend,
        configuration: CloudKitSyncConfig = .init()
    ) {
        self.persistence = persistence
        self.store = store
        self.configuration = configuration
        self.backend = backend
    }
}

extension CloudKitSync {
    public func subscribeToRemoteChanges() async throws {
        // In un prossimo step: creare CKDatabaseSubscription e gestire silent push
        // per poi chiamare await sync() su ricezione.
    }
}

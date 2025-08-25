//
//  CloudkitSync.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation
import CloudKit
import Combine

// Simple async debouncer for coalescing multiple pull triggers
actor AsyncDebouncer {
    private let delayNs: UInt64
    private var task: Task<Void, Never>?

    init(milliseconds: Int) {
        self.delayNs = UInt64(milliseconds) * 1_000_000
    }

    func schedule(_ block: @escaping () async -> Void) {
        task?.cancel()
        task = Task { [delayNs] in
            // Small debounce window
            try? await Task.sleep(nanoseconds: delayNs)
            guard !Task.isCancelled else { return }
            await block()
        }
    }
}

/// Forces a block to run within a max interval even if events keep arriving (deadline flush)
actor _DeadlineFlusher {
    private let intervalNs: UInt64
    private var task: Task<Void, Never>?

    init(seconds: Double) {
        self.intervalNs = UInt64(seconds * 1_000_000_000)
    }

    func schedule(_ block: @escaping () async -> Void) {
        // If a flush is already scheduled, do nothing
        guard task == nil else { return }
        task = Task { [intervalNs] in
            try? await Task.sleep(nanoseconds: intervalNs)
            guard !Task.isCancelled else { return }
            await block()
            task = nil
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

public final class CloudKitSync: GraphSyncEngine {
    internal let persistence: GraphPersistenceController
    internal let store: GraphStore
    internal let backend: RemoteSyncBackend
    internal(set) public var isSyncing: Bool = false
    private let pullDebouncer: AsyncDebouncer
    private let syncDebouncer: AsyncDebouncer
    private let pushDebouncer: AsyncDebouncer
    private var cancellables = Set<AnyCancellable>()

    // Tracks last-pushed timestamps to avoid pushing the whole store every time
    internal var lastPushedEntityTimestamp: [UUID: Date] = [:]
    internal var lastPushedRelationshipTimestamp: [UUID: Date] = [:]

    // Config conservata per debug/telemetria o subscribeOnInit
    public let configuration: CloudKitSyncConfig

    private let deadlineFlusher: _DeadlineFlusher
    private let pushBatchSize: Int
    private let pushMaxIntervalSeconds: Double

    /// Iniezione standard: CKSyncEngineBackend costruito da config.
    @MainActor
    public init(
        persistence: GraphPersistenceController,
        store: GraphStore,
        configuration: CloudKitSyncConfig,
        container: CKContainer
    ) {
        self.persistence = persistence
        self.store = store
        self.configuration = configuration
        _CKAttachmentThreshold.bytes = max(0, configuration.assetThresholdBytes)
        self.pullDebouncer = AsyncDebouncer(milliseconds: configuration.debounceMilliseconds)
        self.syncDebouncer = AsyncDebouncer(milliseconds: configuration.debounceMilliseconds)
        self.pushDebouncer = AsyncDebouncer(milliseconds: configuration.debounceMilliseconds)
        self.deadlineFlusher = _DeadlineFlusher(seconds: configuration.pushMaxIntervalSeconds)
        self.pushBatchSize = configuration.pushBatchSize
        self.pushMaxIntervalSeconds = configuration.pushMaxIntervalSeconds

        // Costruzione del backend reale basato su CKSyncEngine e sulla zone configurata.
        let zoneID = CKRecordZone.ID(zoneName: configuration.zoneName)
        self.backend = CKSyncEngineBackend(
            container: container,
            zoneID: zoneID,
            stateStore: configuration.stateStore,
            subscriptionID: configuration.subscriptionID,
            retryMaxAttempts: configuration.retryMaxAttempts,
            retryBaseDelaySeconds: configuration.retryBaseDelaySeconds
        )
        if configuration.subscribeOnInit {
            // non lancia: puoi farlo async separato se preferisci
            Task { try? await self.subscribeToRemoteChanges() }
        }
        startObservingStore()
    }

    /// Iniezione alternativa per test: backend mock o custom.
    @MainActor
    init(
        persistence: GraphPersistenceController,
        store: GraphStore,
        backend: RemoteSyncBackend,
        configuration: CloudKitSyncConfig = .init()
    ) {
        self.persistence = persistence
        self.store = store
        self.configuration = configuration
        _CKAttachmentThreshold.bytes = max(0, configuration.assetThresholdBytes)
        self.pullDebouncer = AsyncDebouncer(milliseconds: configuration.debounceMilliseconds)
        self.syncDebouncer = AsyncDebouncer(milliseconds: configuration.debounceMilliseconds)
        self.pushDebouncer = AsyncDebouncer(milliseconds: configuration.debounceMilliseconds)
        self.deadlineFlusher = _DeadlineFlusher(seconds: configuration.pushMaxIntervalSeconds)
        self.pushBatchSize = configuration.pushBatchSize
        self.pushMaxIntervalSeconds = configuration.pushMaxIntervalSeconds
        self.backend = backend
        startObservingStore()
    }

    private func lastModifiedDate(of entity: Entity) -> Date {
        entity.updated?.at ?? entity.created.at
    }

    private func lastModifiedDate(of relationship: Relationship) -> Date {
        relationship.updated?.at ?? relationship.created.at
    }
}

extension CloudKitSync {
    public func subscribeToRemoteChanges() async throws {
        try await backend.subscribeToRemoteChanges()
    }
    
    // MARK: - Retry helper (frontend)
    private func withRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        let maxAttempts = configuration.retryMaxAttempts
        let base = configuration.retryBaseDelaySeconds
        for attempt in 1...maxAttempts {
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
                    if retryable.contains(ckErr.code), attempt < maxAttempts {
                        let delay = base * pow(2, Double(attempt - 1))
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                throw error
            }
        }
        throw lastError ?? NSError(domain: "CloudKitSync.withRetry", code: -1)
    }
    
    /// Coalesces multiple remote-change hints into a single pull() after a short delay.
    public func triggerPullDebounced() {
        let weakSelf = self
        Task { [weak weakSelf] in
            await pullDebouncer.schedule { [weak weakSelf] in
                guard let self = weakSelf else { return }
                do {
                    _ = try await self.withRetry { try await self.pull() }
                } catch {
                    // optionally log
                }
            }
        }
    }
    
    /// NOTE: attualmente non collegata alle notifiche remote; usata solo per trigger manuali/locali.
    /// Coalesces multiple remote-change hints into a single sync() after a short delay (pull → push).
    public func triggerSyncDebounced() {
        let weakSelf = self
        Task { [weak weakSelf] in
            await syncDebouncer.schedule { [weak weakSelf] in
                guard let self = weakSelf else { return }
                do {
                    _ = try await self.withRetry { try await self.sync() }
                } catch {
                    // optionally log
                }
            }
        }
    }
    
    /// Called from AppDelegate/SceneDelegate when a CKNotification arrives.
    @discardableResult
    public func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            return false
        }
        switch notification.notificationType {
        case .database, .recordZone, .query:
            // Schedule a debounced pull when we detect relevant remote changes
            triggerPullDebounced()
        default:
            break
        }
        return true
        // TODO: Documentare che questa funzione deve essere richiamata da AppDelegate/SceneDelegate
        //       (es. in didReceiveRemoteNotification)
    }
    
    public func push() async throws {
        isSyncing = true
        defer { isSyncing = false }

        // 1) Snapshot current nodes from the store
        let allEntities = await store.allEntities()
        let allRelationships = await store.allRelationships()

        // 2) Filter only nodes changed since last successful push
        let entitiesToPush = allEntities.filter { e in
            let ts = lastModifiedDate(of: e)
            guard let prev = lastPushedEntityTimestamp[e.id] else { return true }
            return ts > prev
        }
        let relationshipsToPush = allRelationships.filter { r in
            let ts = lastModifiedDate(of: r)
            guard let prev = lastPushedRelationshipTimestamp[r.id] else { return true }
            return ts > prev
        }

        // 3) If nothing to push, exit early
        if entitiesToPush.isEmpty, relationshipsToPush.isEmpty { return }

        // 4) Push incrementally in batches (wrapped in retry/backoff)
        func chunks<T>(_ array: [T], size: Int) -> [[T]] {
            guard size > 0, array.count > size else { return array.isEmpty ? [] : [array] }
            var result: [[T]] = []
            var idx = 0
            while idx < array.count {
                let end = min(idx + size, array.count)
                result.append(Array(array[idx..<end]))
                idx = end
            }
            return result
        }

        try await withRetry {
            // Entities in batches
            for batch in chunks(entitiesToPush, size: self.pushBatchSize) {
                try await self.backend.save(entities: batch)
                for e in batch {
                    self.lastPushedEntityTimestamp[e.id] = self.lastModifiedDate(of: e)
                }
            }
            // Relationships in batches
            for batch in chunks(relationshipsToPush, size: self.pushBatchSize) {
                try await self.backend.save(relationships: batch)
                for r in batch {
                    self.lastPushedRelationshipTimestamp[r.id] = self.lastModifiedDate(of: r)
                }
            }
        }
    }
    
    @MainActor private func startObservingStore() {
        store.changeFeed
            .sink { [weak self] change in
                guard let self = self else { return }

                // Ignora modifiche remote per evitare loop
                switch change {
                case .insert(_, let isRemote),
                     .update(_, let isRemote),
                     .remove(_, let isRemote):
                    if !isRemote {
                        self.triggerLocalPushDebounced()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func triggerLocalPushDebounced() {
        let weakSelf = self
        Task { [weak weakSelf] in
            await pushDebouncer.schedule { [weak weakSelf] in
                guard let self = weakSelf else { return }
                do {
                    _ = try await self.withRetry { try await self.push() }
                } catch {
                    // opzionale: log
                }
            }
        }
        // Deadline: guarantee a push within the max interval even under continuous changes
        Task { [weak weakSelf] in
            await weakSelf?.deadlineFlusher.schedule { [weak weakSelf] in
                guard let self = weakSelf else { return }
                do {
                    _ = try await self.withRetry { try await self.push() }
                } catch {
                    // optionally log
                }
            }
        }
    }
}

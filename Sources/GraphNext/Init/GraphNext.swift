//
//  GraphNext.swift
//  GraphNext
//
//  Created by Valerio Buriani on 21/08/25.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

// MARK: - Errori GraphNext
public enum GraphNextError: Error {
    case missingPersistenceFactory
}

// MARK: - AccountDescriptor (nessun coupling con auth)
public enum AccountDescriptor: Equatable, Codable {
    case localOnly
    case iCloud(userRecordName: String?)
    case custom(id: String)
}

// MARK: - Preload hook (opzionale)
// Se il controller di persistenza adotta questo protocollo, GraphNext lo userà al bootstrap.
public protocol GraphPersistencePreloader {
    func preload(into store: GraphStore) throws
}

// MARK: - Config
/// Configurazione dichiarativa per il bootstrap di GraphNext.
/// - Nota: i backend vengono creati tramite `makeBackends` per evitare accoppiamenti
///   con implementazioni concrete o factory specifiche. In questo modo l’entry point
///   resta stabile e testabile.
public struct GraphNextConfig {
    /// Abilita la cache volatile opzionale nello `GraphStore`.
    public var useNSCache: Bool
    /// Se `true`, lo store Core Data viene creato in‑memory (utile per test/preview).
    public var inMemoryStore: Bool
    /// Nome logico dello store (verrà passato al persistence).
    public var storeName: String
    /// Se `true`, tenta un pre‑caricamento iniziale dal persistence allo store.
    public var preloadFromPersistence: Bool
    /// Se `true`, all’avvio esegue `pull()` e poi `push()` su ciascun backend.
    public var autoSyncOnLaunch: Bool
    /// Quota massima per la cache file degli asset (in byte). 0 = disattivata. Default: 200 MB
    public var assetCacheQuotaBytes: Int
    /// Strategia per derivare il nome dello store in funzione dell’account/logica d’istanza.
    public var storeNameForAccount: (AccountDescriptor) -> String
    /// Identificativo univoco dell’istanza (prefissi subscription/notifiche, telemetria, ecc.).
    public var instanceID: String
    /// Factory per creare il controller di persistenza concreto (Core Data, ecc.).
    public var makePersistence: (_ storeName: String, _ inMemory: Bool) throws -> GraphPersistenceController
    /// Factory per creare i backend di sincronizzazione (CloudKit, mock, ecc.).
    /// Ritorna la lista di engine già costruiti e pronti all’uso.
    public var makeBackends: (_ store: GraphStore, _ persistence: GraphPersistenceController, _ instanceID: String) throws -> [any GraphSyncEngine]
    
    public var storage: [String: Any] = [:]

    // MARK: Inizializzatore con default sensati
    public init(
        useNSCache: Bool = false,
        inMemoryStore: Bool = false,
        storeName: String = "GraphNext",
        preloadFromPersistence: Bool = true,
        autoSyncOnLaunch: Bool = false,
        assetCacheQuotaBytes: Int = 200 * 1024 * 1024,
        storeNameForAccount: @escaping (AccountDescriptor) -> String = { descriptor in
            switch descriptor {
            case .localOnly:
                return "GraphNext_Local"
            case .iCloud(let user):
                if let u = user, !u.isEmpty { return "GraphNext_iCloud_\(u)" }
                return "GraphNext_iCloud"
            case .custom(let id):
                return "GraphNext_\(id)"
            }
        },
        instanceID: String = UUID().uuidString,
        makePersistence: @escaping (_ storeName: String, _ inMemory: Bool) throws -> GraphPersistenceController
            = { _, _ in throw GraphNextError.missingPersistenceFactory },
        makeBackends: @escaping (_ store: GraphStore, _ persistence: GraphPersistenceController, _ instanceID: String) throws -> [any GraphSyncEngine]
            = { _, _, _ in [] }
    ) {
        self.useNSCache = useNSCache
        self.inMemoryStore = inMemoryStore
        self.storeName = storeName
        self.preloadFromPersistence = preloadFromPersistence
        self.autoSyncOnLaunch = autoSyncOnLaunch
        self.assetCacheQuotaBytes = max(0, assetCacheQuotaBytes)
        self.storeNameForAccount = storeNameForAccount
        self.instanceID = instanceID
        self.makePersistence = makePersistence
        self.makeBackends = makeBackends
    }
    
    public enum PersistenceKind {
        case grdb
        case coreData
    }

    public var persistenceKind: PersistenceKind {
        get { storage["persistenceKind"] as? PersistenceKind ?? .grdb }
        set { storage["persistenceKind"] = newValue }
    }

    public var databaseName: String {
        get { storage["databaseName"] as? String ?? "GraphNext" }
        set { storage["databaseName"] = newValue }
    }
}

@MainActor
public final class GraphNext: ObservableObject {

    public let store: GraphStore
    public let persistence: GraphPersistenceController
    public private(set) var syncEngines: [any GraphSyncEngine] = []

    /// Entry point: costruisce `GraphStore`, `GraphPersistenceController`, opzionale preload e backend.
    /// Se `autoSyncOnLaunch` è `true`, avvia `pull()` → `push()` per ogni backend in sequenza.
    public init(config: GraphNextConfig) throws {
        // 1) Store (@MainActor + ObservableObject)
        self.store = GraphStore(useNSCache: config.useNSCache)

        // 2) Persistence (iniettata tramite factory; il modello Core Data viene caricato in GraphPersistence via Bundle.module)
        self.persistence = try config.makePersistence(config.storeName, config.inMemoryStore)

        // 3) Preload opzionale dallo store (se supportato)
        if config.preloadFromPersistence,
           let preloader = (self.persistence as Any) as? GraphPersistencePreloader {
            try preloader.preload(into: self.store)
        }

        // 3.5) Configure default FileAssetStorage with configured quota (if caller has not set a custom storage)
        do {
            let base = try FileAssetStorage.makeDefaultBaseDirectory()
            let storage = try FileAssetStorage(baseDirectory: base, quotaBytes: config.assetCacheQuotaBytes)
            AssetStorageProvider.shared.setStorage(storage)
        } catch {
            #if DEBUG
            print("GraphNext: failed to configure default FileAssetStorage with quota: \(error)")
            #endif
        }

        // 4) Backend engines (delegato alla factory fornita nel config)
        self.syncEngines = try config.makeBackends(self.store, self.persistence, config.instanceID)

        // 5) AutoSync on launch: pull() → push() per ogni backend, in sequenza (non blocca l’init)
        if config.autoSyncOnLaunch, !self.syncEngines.isEmpty {
            Task(priority: .utility) { [engines = self.syncEngines] in
                for engine in engines {
                    do {
                        try await engine.pull()
                        try await engine.push()
                    } catch {
                        #if DEBUG
                        print("GraphNext autoSync error on \(engine): \(error)")
                        #endif
                    }
                }
            }
        }
    }
}

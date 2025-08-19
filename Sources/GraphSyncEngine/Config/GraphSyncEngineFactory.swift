//
//  GraphSyncEngineFactory.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/08/25.
//

import Foundation
import CloudKit
import GraphNext
import GraphPersistence

/// Factory che restituisce l'implementazione concreta di GraphSyncEngine in base al backend scelto.
public enum GraphSyncEngineFactory {
    @MainActor
    public static func make(
        backend: SyncBackendKind,
        store: GraphStore,
        persistence: GraphPersistenceController
    ) -> GraphSyncEngine {
        switch backend {
        case .cloudKit(let cfg):
            let container: CKContainer = {
                if let id = cfg.containerIdentifier {
                    return CKContainer(identifier: id)
                } else {
                    return .default()
                }
            }()
            let engine = CloudKitSync(
                persistence: persistence,
                store: store,
                configuration: cfg,
                container: container
            )
            return engine

        case .firebase:
            // return FirebaseSync(persistence: persistence, store: store, configuration: cfg)
            fatalError("Firebase backend non ancora implementato.")
        case .rest:
            // return RestSync(persistence: persistence, store: store, configuration: cfg)
            fatalError("REST backend non ancora implementato.")
        }
    }
}

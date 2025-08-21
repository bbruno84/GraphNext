//
//  SyncBackendKind.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/08/25.
//

import Foundation

/// Backend supportati dal GraphSyncEngine.
/// Ogni caso incapsula la relativa configurazione tipizzata.
public enum SyncBackendKind: Codable, Equatable {
    case cloudKit(CloudKitSyncConfig)
    case firebase(FirebaseSyncConfig)      // placeholder per il futuro
    case rest(RestSyncConfig)              // placeholder per il futuro
}

/// Configurazioni “vuote” per backend futuri.
// Puoi sostituirle quando svilupperemo i plugin relativi.
public struct FirebaseSyncConfig: Codable, Equatable {
    public init() {}
}
public struct RestSyncConfig: Codable, Equatable {
    public init() {}
}

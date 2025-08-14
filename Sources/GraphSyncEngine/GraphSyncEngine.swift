//
//  GraphSyncEngine.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

//
//  GraphSyncEngine.swift
//  GraphNext
//

import Foundation

/// Contratto di sincronizzazione tra GraphStore e un backend remoto.
public protocol GraphSyncEngine {
    /// Recupera modifiche dal backend e le applica localmente.
    func pull() async throws
    /// Spinge le modifiche locali verso il backend.
    func push() async throws
    /// Esegue una sincronizzazione completa (pull → push).
    func sync() async throws
    /// Svuota lo stato locale e riallinea al backend.
    func reset() async throws
    /// (Opzionale) Sottoscrive le modifiche remote (push/silent notifications, delta sync, ecc.).
    func subscribeToRemoteChanges() async throws

    /// Stato corrente di sincronizzazione (per UI/telemetria).
    var isSyncing: Bool { get }
}

/// Implementazioni di default non vincolanti.
public extension GraphSyncEngine {
    func subscribeToRemoteChanges() async throws { /* no-op */ }
    var isSyncing: Bool { false }
}

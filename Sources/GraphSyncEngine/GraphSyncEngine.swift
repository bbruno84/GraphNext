//
//  GraphSyncEngine.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation

/// Protocollo di base per qualsiasi motore di sincronizzazione.
/// Deve garantire supporto alla sincronizzazione bidirezionale tra GraphStore e un backend remoto.
public protocol GraphSyncEngine {
    /// Recupera tutte le modifiche dal backend e le applica localmente.
    func pull() async throws

    /// Spinge tutte le modifiche locali verso il backend.
    func push() async throws

    /// Esegue una sincronizzazione completa (pull + push).
    func sync() async throws

    /// Resetta completamente lo stato locale e lo riallinea al backend.
    func reset() async throws
}

//
//  CloudKitSyncConfig.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/08/25.
//

import Foundation

/// Configurazione del plugin CloudKitSync basato su CKSyncEngine.
public struct CloudKitSyncConfig: Codable, Equatable {
    /// Esempio: "iCloud.com.tuaazienda.GraphNext". Se nil → CKContainer.default()
    public var containerIdentifier: String?
    /// Nome della record zone (se vuoi usarne una dedicata).
    public var zoneName: String
    /// Persistenza dei change tokens di CKSyncEngine.
    public var stateStore: StateStore
    /// Abilita la sottoscrizione automatica a modifiche remote.
    public var subscribeOnInit: Bool
    /// Identificativo della subscription CloudKit (usato per le push). Default: "GraphNextSyncSubscription"
    public var subscriptionID: String
    /// Finestra di debounce (ms) per coalescere più trigger di pull ravvicinati. Default: 750
    public var debounceMilliseconds: Int
    /// Numero massimo di tentativi per operazioni CloudKit retryable. Default: 3
    public var retryMaxAttempts: Int
    /// Delay base (secondi) per exponential backoff. Default: 0.5s
    public var retryBaseDelaySeconds: Double

    public init(
        containerIdentifier: String? = nil,
        zoneName: String = "GraphNextZone",
        stateStore: StateStore = .userDefaults(suiteName: "CKSE.GraphNextState"),
        subscribeOnInit: Bool = false,
        subscriptionID: String = "GraphNextSyncSubscription",
        debounceMilliseconds: Int = 750,
        retryMaxAttempts: Int = 3,
        retryBaseDelaySeconds: Double = 0.5
    ) {
        self.containerIdentifier = containerIdentifier
        self.zoneName = zoneName
        self.stateStore = stateStore
        self.subscribeOnInit = subscribeOnInit
        self.subscriptionID = subscriptionID
        self.debounceMilliseconds = debounceMilliseconds
        self.retryMaxAttempts = retryMaxAttempts
        self.retryBaseDelaySeconds = retryBaseDelaySeconds
    }

    /// Dove CKSyncEngine salva il proprio stato (change tokens).
    public enum StateStore: Codable, Equatable {
        case userDefaults(suiteName: String)
        case fileSystem(path: String)
    }
}

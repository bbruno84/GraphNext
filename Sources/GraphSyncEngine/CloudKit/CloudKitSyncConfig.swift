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

    public init(
        containerIdentifier: String? = nil,
        zoneName: String = "GraphNextZone",
        stateStore: StateStore = .userDefaults(suiteName: "CKSE.GraphNextState"),
        subscribeOnInit: Bool = false
    ) {
        self.containerIdentifier = containerIdentifier
        self.zoneName = zoneName
        self.stateStore = stateStore
        self.subscribeOnInit = subscribeOnInit
    }

    /// Dove CKSyncEngine salva il proprio stato (change tokens).
    public enum StateStore: Codable, Equatable {
        case userDefaults(suiteName: String)
        case fileSystem(path: String)
    }
}

//
//  CloudKitSync+Reset.swift
//  GraphNext
//
//  Created by Valerio Buriani on 03/08/25.
//

import Foundation

extension CloudKitSync {
    public func reset() async throws {
        isSyncing = true
        defer { isSyncing = false }

        await store.clear(isRemote: true)
        // Clear incremental push watermarks
        lastPushedEntityTimestamp.removeAll()
        lastPushedRelationshipTimestamp.removeAll()
        try await pull() // remote-wins: riallinea dal backend
    }
}

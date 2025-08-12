//
//  CloudKitSync+Sync.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation

extension CloudKitSync {
    public func sync() async throws {
        try await pull()
        try await push()
    }
}


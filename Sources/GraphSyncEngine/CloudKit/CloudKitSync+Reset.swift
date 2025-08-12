//
//  CloudKitSync+Reset.swift
//  GraphNext
//
//  Created by Valerio Buriani on 03/08/25.
//

//
//  CloudKitSync+Reset.swift
//  GraphNext
//
//  Created by ChatGPT on 03/08/25.
//

import Foundation
import GraphNext
import CloudKit

extension CloudKitSync {
    public func reset() async throws {
        // 1. Svuota completamente lo stato locale
        store.clear()

        // 2. Ricarica tutto da CloudKit
        try await pull()
    }
}

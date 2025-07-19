//
//  AuditInfo.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation

public struct AuditInfo: Codable, Equatable, Hashable {
    public var by: String
    public var at: Date

    public init(by: String, at: Date = Date()) {
        self.by = by
        self.at = at
    }
}

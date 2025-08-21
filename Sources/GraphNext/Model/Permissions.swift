//
//  Permission.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation

public struct Permissions: Codable, Equatable, Hashable {
    public enum AccessLevel: String, Codable {
        case read
        case write
        case admin
    }

    // userID (es. Apple ID, UUID del sistema, ecc.) → livello di accesso
    public var users: [String: AccessLevel]

    public init(users: [String: AccessLevel] = [:]) {
        self.users = users
    }
}

//
//  GraphNode.swift
//  GraphNext
//
//  Created by Valerio Buriani on 21/08/25.
//

import Foundation

// MARK: - GraphNode Protocol
public protocol GraphNode: Identifiable, Hashable {
    var id: UUID { get }
    var type: String { get }
    var tag: Set<String> { get set }
    var group: Set<String> { get set }
    var indexed: [String: String] { get set }
    var created: AuditInfo { get set }
    var updated: AuditInfo? { get set }
    var version: Int? { get set }
    var sharedWith: [String] { get set }
    var permissions: Permissions? { get set }
}

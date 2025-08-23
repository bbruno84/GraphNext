//
//  GRDBGraphPersistenceController+Queries.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//
import Foundation
import GRDB

extension GRDBGraphPersistenceController {

    private func asDatabaseValue(_ value: GraphPayloadValue) -> DatabaseValue {
        switch value {
        case .string(let str): return str.databaseValue
        case .int(let int): return int.databaseValue
        case .double(let dbl): return dbl.databaseValue
        case .bool(let b): return (b ? 1 : 0).databaseValue
        case .date(let date): return date.timeIntervalSince1970.databaseValue
        }
    }

    // MARK: - Query

    public func queryEntities(matching type: String?) async throws -> [Entity] {
        try await dbQueue.read { db in
            let sql: String
            let arguments: StatementArguments

            if let type = type {
                sql = "SELECT * FROM entities WHERE type = ?"
                arguments = [type]
            } else {
                sql = "SELECT * FROM entities"
                arguments = []
            }

            let rows = try Row.fetchAll(db, sql: sql, arguments: arguments)
            return try rows.compactMap(self.decodeEntity(from:))
        }
    }

    public func queryRelationships(matching type: String?) async throws -> [Relationship] {
        try await dbQueue.read { db in
            let sql: String
            let arguments: StatementArguments

            if let type {
                sql = "SELECT * FROM relationships WHERE type = ?"
                arguments = [type]
            } else {
                sql = "SELECT * FROM relationships"
                arguments = []
            }

            let rows = try Row.fetchAll(db, sql: sql, arguments: arguments)
            return try rows.compactMap(self.decodeRelationship(from:))
        }
    }

    public func queryEntities(wherePayloadKey key: String, equals value: GraphPayloadValue) async throws -> [Entity] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let jsonValue = self.asDatabaseValue(value)
            let sql = "SELECT * FROM entities WHERE \(columnPath) = ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [jsonValue])
            return try rows.compactMap(self.decodeEntity(from:))
        }
    }

    public func queryRelationships(wherePayloadKey key: String, equals value: GraphPayloadValue) async throws -> [Relationship] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let jsonValue = self.asDatabaseValue(value)
            let sql = "SELECT * FROM relationships WHERE \(columnPath) = ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [jsonValue])
            return try rows.compactMap(self.decodeRelationship(from:))
        }
    }

    public func queryEntities(wherePayloadKey key: String, greaterThan value: GraphPayloadValue) async throws -> [Entity] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM entities WHERE \(columnPath) > ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(value)])
            return try rows.compactMap(self.decodeEntity(from:))
        }
    }

    public func queryRelationships(wherePayloadKey key: String, greaterThan value: GraphPayloadValue) async throws -> [Relationship] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM relationships WHERE \(columnPath) > ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(value)])
            return try rows.compactMap(self.decodeRelationship(from:))
        }
    }
    
    public func queryEntities(wherePayloadKey key: String, lessThan value: GraphPayloadValue) async throws -> [Entity] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM entities WHERE \(columnPath) < ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(value)])
            return try rows.compactMap(self.decodeEntity(from:))
        }
    }

    public func queryEntities(wherePayloadKey key: String, greaterThanOrEqualTo value: GraphPayloadValue) async throws -> [Entity] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM entities WHERE \(columnPath) >= ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(value)])
            return try rows.compactMap(self.decodeEntity(from:))
        }
    }

    public func queryEntities(wherePayloadKey key: String, lessThanOrEqualTo value: GraphPayloadValue) async throws -> [Entity] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM entities WHERE \(columnPath) <= ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(value)])
            return try rows.compactMap(self.decodeEntity(from:))
        }
    }

    public func queryEntities(wherePayloadKey key: String, between lower: GraphPayloadValue, and upper: GraphPayloadValue) async throws -> [Entity] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM entities WHERE \(columnPath) BETWEEN ? AND ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(lower), self.asDatabaseValue(upper)])
            return try rows.compactMap(self.decodeEntity(from:))
        }
    }

    public func queryRelationships(wherePayloadKey key: String, lessThan value: GraphPayloadValue) async throws -> [Relationship] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM relationships WHERE \(columnPath) < ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(value)])
            return try rows.compactMap(self.decodeRelationship(from:))
        }
    }

    public func queryRelationships(wherePayloadKey key: String, greaterThanOrEqualTo value: GraphPayloadValue) async throws -> [Relationship] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM relationships WHERE \(columnPath) >= ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(value)])
            return try rows.compactMap(self.decodeRelationship(from:))
        }
    }

    public func queryRelationships(wherePayloadKey key: String, lessThanOrEqualTo value: GraphPayloadValue) async throws -> [Relationship] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM relationships WHERE \(columnPath) <= ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(value)])
            return try rows.compactMap(self.decodeRelationship(from:))
        }
    }

    public func queryRelationships(wherePayloadKey key: String, between lower: GraphPayloadValue, and upper: GraphPayloadValue) async throws -> [Relationship] {
        try await dbQueue.read { db in
            let columnPath = "json_extract(payload, '$.\(key).value')"
            let sql = "SELECT * FROM relationships WHERE \(columnPath) BETWEEN ? AND ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [self.asDatabaseValue(lower), self.asDatabaseValue(upper)])
            return try rows.compactMap(self.decodeRelationship(from:))
        }
    }

    public func relatedEntities(from entityId: UUID) async throws -> [Entity] {
        try await dbQueue.read { db in
            let sql = """
            SELECT e.* FROM relationships r
            JOIN entities e ON e.id = r.toId
            WHERE r.fromId = ?
            """
            let rows = try Row.fetchAll(db, sql: sql, arguments: [entityId.uuidString])
            return try rows.compactMap(self.decodeEntity(from:))
        }
    }
    
    public func relatedRelationships(from entityId: UUID) async throws -> [Relationship] {
        try await dbQueue.read { db in
            let sql = "SELECT * FROM relationships WHERE fromId = ?"
            let rows = try Row.fetchAll(db, sql: sql, arguments: [entityId.uuidString])
            return try rows.compactMap(self.decodeRelationship(from:))
        }
    }
}

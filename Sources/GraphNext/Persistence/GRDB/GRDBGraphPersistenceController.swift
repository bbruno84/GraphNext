//
//  GRDBGraphPersistenceController.swift
//  GraphNext
//
//  Created by Regia GraphNext on 23/08/2025.
//

import Foundation
import GRDB

public final class GRDBGraphPersistenceController: GraphPersistenceController {
    
    internal let dbQueue: DatabaseQueue
    
    // Assets helper
    private var assetStorage: AssetStorage { AssetStorageProvider.shared.storage }

    public init(path: String, inMemory: Bool = false) throws {
        var config = Configuration()
        config.prepareDatabase { db in
            // Executed outside of transactions on each new connection
            try! db.execute(sql: "PRAGMA foreign_keys = ON;")
            try! db.execute(sql: "PRAGMA journal_mode = WAL;")
            try! db.execute(sql: "PRAGMA synchronous = NORMAL;")
        }

        if inMemory {
            dbQueue = try DatabaseQueue(configuration: config)
        } else {
            dbQueue = try DatabaseQueue(path: path, configuration: config)
        }

        // Apply schema migrations
        let migrator = GraphDBMigrations.makeMigrator()
        try migrator.migrate(dbQueue)
    }

    // MARK: - Entity

    public func saveEntity(_ entity: Entity) async throws {
        try await dbQueue.write { db in
            let encodedTags = try self.encodeJSON(Array(entity.tag))
            let encodedGroup = try self.encodeJSON(Array(entity.group))
            let encodedSharedWith = try self.encodeJSON(Array(entity.sharedWith))
            try db.execute(
                sql: """
                INSERT OR REPLACE INTO entities (id, type, groupName, tags, payload, createdAt, createdBy, updatedAt, updatedBy, sharedWith)
                VALUES (:id, :type, :groupName, :tags, :payload, :createdAt, :createdBy, :updatedAt, :updatedBy, :sharedWith)
                """,
                arguments: [
                    "id": entity.id.uuidString,
                    "type": entity.type,
                    "groupName": encodedGroup,
                    "tags": encodedTags,
                    "payload": try self.encodeJSON(entity.payload),
                    "createdAt": entity.created.at.timeIntervalSince1970,
                    "createdBy": entity.created.by,
                    "updatedAt": entity.updated?.at.timeIntervalSince1970,
                    "updatedBy": entity.updated?.by,
                    "sharedWith": encodedSharedWith
                ]
            )
        }
    }

    public func entity(id: UUID) async throws -> Entity? {
        try await dbQueue.read { db in
            let row = try Row.fetchOne(db, sql: "SELECT * FROM entities WHERE id = ?", arguments: [id.uuidString])
            return try row.flatMap(self.decodeEntity(from:))
        }
    }

    public func deleteEntity(id: UUID) async throws {
        // Pre-fetch: capiamo se è un asset
        let existing = try await entity(id: id)
        if existing?.type == "asset" {
            // Best-effort: rimuovi file e indice locale (non bloccare la cancellazione DB se fallisce)
            try? assetStorage.remove(assetId: id)
        }
        // Poi elimina da DB (relationships + entity)
        try await dbQueue.write { db in
            try db.execute(sql: "DELETE FROM relationships WHERE fromId = ? OR toId = ?", arguments: [id.uuidString, id.uuidString])
            try db.execute(sql: "DELETE FROM entities WHERE id = ?", arguments: [id.uuidString])
        }
    }

    public func deleteEntityAndAttachedRelationships(id: UUID) async throws {
        try await deleteEntity(id: id)
    }

    public func saveEntities(_ entities: [Entity]) async throws {
        try await dbQueue.write { db in
            for entity in entities {
                do {
                    let encodedTags = try self.encodeJSON(Array(entity.tag))
                    let encodedGroup = try self.encodeJSON(Array(entity.group))
                    let encodedPayload = try self.encodeJSON(entity.payload)
                    let encodedSharedWith = try self.encodeJSON(Array(entity.sharedWith))

                    try db.execute(
                        sql: """
                        INSERT OR REPLACE INTO entities (id, type, groupName, tags, payload, createdAt, createdBy, updatedAt, updatedBy, sharedWith)
                        VALUES (:id, :type, :groupName, :tags, :payload, :createdAt, :createdBy, :updatedAt, :updatedBy, :sharedWith)
                        """,
                        arguments: [
                            "id": entity.id.uuidString,
                            "type": entity.type,
                            "groupName": encodedGroup,
                            "tags": encodedTags,
                            "payload": encodedPayload,
                            "createdAt": entity.created.at.timeIntervalSince1970,
                            "createdBy": entity.created.by,
                            "updatedAt": entity.updated?.at.timeIntervalSince1970,
                            "updatedBy": entity.updated?.by,
                            "sharedWith": encodedSharedWith
                        ]
                    )
                } catch {
                    throw error
                }
            }
        }
    }

    public func deleteEntities(_ ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }

        // Pre-fetch per individuare quali sono asset
        var assetIDs: [UUID] = []
        for id in ids {
            if let e = try await entity(id: id), e.type == "asset" {
                assetIDs.append(id)
            }
        }

        // Best-effort: rimuovi i file locali degli asset
        for assetId in assetIDs {
            try? assetStorage.remove(assetId: assetId)
        }

        // Cancella da DB (relationships + entities)
        let strings = ids.map(\.uuidString)
        let placeholders = Array(repeating: "?", count: strings.count).joined(separator: ",")
        try await dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM relationships WHERE fromId IN (\(placeholders)) OR toId IN (\(placeholders))",
                arguments: StatementArguments(strings + strings)
            )
            try db.execute(
                sql: "DELETE FROM entities WHERE id IN (\(placeholders))",
                arguments: StatementArguments(strings)
            )
        }
    }

    // MARK: - Relationship

    public func saveRelationship(_ relationship: Relationship) async throws {
        
        try await dbQueue.write { db in
            guard let from = relationship.from, let to = relationship.to else {
                throw NSError(domain: "GraphNext", code: 400, userInfo: [NSLocalizedDescriptionKey: "Relationship requires non-nil from/to"])
            }
            try db.execute(
                sql: """
                INSERT OR REPLACE INTO relationships (id, type, fromId, toId, payload, createdAt, createdBy, updatedAt, updatedBy, tags, groupName, sharedWith, permissions)
                VALUES (:id, :type, :fromId, :toId, :payload, :createdAt, :createdBy, :updatedAt, :updatedBy, :tags, :groupName, :sharedWith, :permissions)
                """,
                arguments: [
                    "id": relationship.id.uuidString,
                    "type": relationship.type,
                    "fromId": from.uuidString,
                    "toId": to.uuidString,
                    "payload": try self.encodeJSON(relationship.payload),
                    "createdAt": relationship.created.at.timeIntervalSince1970,
                    "createdBy": relationship.created.by,
                    "updatedAt": relationship.updated?.at.timeIntervalSince1970,
                    "updatedBy": relationship.updated?.by,
                    "tags": try self.encodeJSON(Array(relationship.tag)),
                    "groupName": try self.encodeJSON(Array(relationship.group)),
                    "sharedWith": try self.encodeJSON(Array(relationship.sharedWith)),
                    "permissions": try self.encodeJSON(relationship.permissions)
                ]
            )
        }
    }

    public func relationship(id: UUID) async throws -> Relationship? {
        try await dbQueue.read { db in
            let row = try Row.fetchOne(db, sql: "SELECT * FROM relationships WHERE id = ?", arguments: [id.uuidString])
            return try row.flatMap(self.decodeRelationship(from:))
        }
    }

    public func deleteRelationship(id: UUID) async throws {
        try await dbQueue.write { db in
            try db.execute(sql: "DELETE FROM relationships WHERE id = ?", arguments: [id.uuidString])
        }
    }

    public func saveRelationships(_ relationships: [Relationship]) async throws {
        for r in relationships {
            try await saveRelationship(r)
        }
    }

    public func deleteRelationships(_ ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        let strings = ids.map(\.uuidString)
        let placeholders = Array(repeating: "?", count: strings.count).joined(separator: ",")
        try await dbQueue.write { db in
            try db.execute(sql: "DELETE FROM relationships WHERE id IN (\(placeholders))", arguments: StatementArguments(strings))
        }
    }

    // MARK: - Fetch all

    public func allEntities() async throws -> [Entity] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM entities")
            return try rows.compactMap(self.decodeEntity(from:))
        }
    }

    public func allRelationships() async throws -> [Relationship] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM relationships")
            return try rows.compactMap(self.decodeRelationship(from:))
        }
    }

    // MARK: - Reset

    public func reset() async throws {
        try await dbQueue.write { db in
            try db.execute(sql: "DELETE FROM relationships")
            try db.execute(sql: "DELETE FROM entities")
        }
    }
    


    // MARK: - Helpers

    private func encodeJSON<T: Encodable>(_ value: T?) throws -> String? {
        guard let value = value else { return nil }
        let data = try JSONEncoder().encode(value)
        return String(data: data, encoding: .utf8)
    }

    internal func decodeEntity(from row: Row) throws -> Entity {
        return Entity(
            id: UUID(uuidString: row["id"])!,
            type: row["type"],
            tag: try decodeJSON(from: row["tags"]) ?? [],
            group: try decodeJSON(from: row["groupName"]) ?? [],
            created: decodeAudit(from: row, prefix: "created")!,
            updated: decodeAudit(from: row, prefix: "updated"),
            version: nil,
            sharedWith: try decodeJSON(from: row["sharedWith"]) ?? [],
            permissions: nil,
            payload: try decodeJSON(from: row["payload"])
        )
    }

    internal func decodeRelationship(from row: Row) throws -> Relationship {
        return Relationship(
            id: UUID(uuidString: row["id"])!,
            type: row["type"],
            tag: try decodeJSON(from: row["tags"]) ?? [],
            group: try decodeJSON(from: row["groupName"]) ?? [],
            created: decodeAudit(from: row, prefix: "created")!,
            updated: decodeAudit(from: row, prefix: "updated"),
            sharedWith: try decodeJSON(from: row["sharedWith"]) ?? [],
            permissions: try decodeJSON(from: row["permissions"]),
            payload: try decodeJSON(from: row["payload"]),
            from: UUID(uuidString: row["fromId"] as! String),
            to: UUID(uuidString: row["toId"] as! String)
        )
    }

    private func decodeJSON<T: Decodable>(from string: String?) throws -> T? {
        guard let string, let data = string.data(using: .utf8) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func decodeAudit(from row: Row, prefix: String) -> AuditInfo? {
        guard
            let timestampRaw = row["\(prefix)At"],
            let timestamp = timestampRaw as? Double
        else {
            return nil
        }

        // force-cast safe: '\(prefix)By' is NOT NULL in schema
        let by = row["\(prefix)By"] as! String
        return AuditInfo(by: by, at: Date(timeIntervalSince1970: timestamp))
    }
}

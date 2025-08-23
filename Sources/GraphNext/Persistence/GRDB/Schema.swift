//
//  Schema.swift
//  GraphNext
//
//  Created by Regia GraphNext on 23/08/2025.
//

import Foundation
import GRDB

enum GraphDBSchema {
    static let entitiesTable = "entities"
    static let relationshipsTable = "relationships"

    static func createEntities(in db: Database) throws {
        try db.create(table: entitiesTable) { t in
            t.column("id", .text).primaryKey()
            t.column("type", .text).notNull()
            t.column("groupName", .text)
            t.column("tags", .text) // JSON string
            t.column("payload", .text) // JSON string
            t.column("createdAt", .double)
            t.column("createdBy", .text)
            t.column("updatedAt", .double)
            t.column("updatedBy", .text)
        }

        try db.create(index: "idx_entities_type", on: entitiesTable, columns: ["type"])
    }

    static func createRelationships(in db: Database) throws {
        try db.create(table: relationshipsTable) { t in
            t.column("id", .text).primaryKey()
            t.column("type", .text).notNull()
            t.column("fromId", .text).notNull()
            t.column("toId", .text).notNull()
            t.column("payload", .text) // JSON string
            t.column("createdAt", .double)
            t.column("createdBy", .text)
            t.column("updatedAt", .double)
            t.column("updatedBy", .text)
        }

        try db.create(index: "idx_rel_from", on: relationshipsTable, columns: ["fromId"])
        try db.create(index: "idx_rel_to", on: relationshipsTable, columns: ["toId"])
    }
}

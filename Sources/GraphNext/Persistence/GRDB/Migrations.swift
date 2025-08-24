//  Migrations.swift
//  GraphNext
//
//  Created by Regia GraphNext on 23/08/2025.
//

import Foundation
import GRDB

enum GraphDBMigrations {
    static let schemaVersion: Int = 1

    static func makeMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_entities_and_relationships") { db in
            try GraphDBSchema.createEntities(in: db)
            try GraphDBSchema.createRelationships(in: db)
        }
        

        migrator.registerMigration("drop_legacy_asset_blobs_if_exists") { db in
            // Safe cleanup for pre-PR2 development databases
            try db.execute(sql: "DROP INDEX IF EXISTS idx_asset_blobs_entityId;")
            try db.execute(sql: "DROP INDEX IF EXISTS idx_asset_blobs_sha256;")
            try db.execute(sql: "DROP TABLE IF EXISTS asset_blobs;")
        }

        return migrator
    }
}

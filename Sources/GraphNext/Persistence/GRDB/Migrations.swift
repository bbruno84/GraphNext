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
        
        migrator.registerMigration("createAssetBlobs") { db in
            try db.execute(sql: """
                CREATE TABLE asset_blobs (
                    entityId TEXT PRIMARY KEY
                        REFERENCES entities(id) ON DELETE CASCADE,
                    data     BLOB NOT NULL,
                    length   INTEGER NOT NULL,
                    sha256   TEXT NOT NULL,
                    mimeType TEXT,
                    fileName TEXT
                )
                """)
        }

        return migrator
    }
}

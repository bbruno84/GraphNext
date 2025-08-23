//
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

        return migrator
    }
}

//
//  GRDBMigrationTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//


import XCTest
import GRDB
@testable import GraphNext

final class GRDBMigrationTests: XCTestCase {
    
    func testDatabaseSchemaAfterMigration() throws {
        // Create in-memory DB and apply migrations
        let dbQueue = try DatabaseQueue()
        let migrator = GraphDBMigrations.makeMigrator()
        try migrator.migrate(dbQueue)
        
        try dbQueue.read { db in
            // ✅ Check required tables exist
            let requiredTables = ["entities", "relationships"]
            for table in requiredTables {
                let count = try Int.fetchOne(
                    db,
                    sql: "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = ?",
                    arguments: [table]
                )
                XCTAssertEqual(count, 1, "Missing table: \(table)")
            }
            
            // ❌ Ensure legacy table `asset_blobs` has been dropped (PR3)
            let legacyCount = try Int.fetchOne(
                db,
                sql: "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = ?",
                arguments: ["asset_blobs"]
            )
            XCTAssertEqual(legacyCount, 0, "Legacy table asset_blobs should not exist after migrations")
            
            // ✅ Check required indices exist
            let requiredIndices = ["idx_entities_type", "idx_rel_from", "idx_rel_to"]
            for index in requiredIndices {
                let count = try Int.fetchOne(
                    db,
                    sql: "SELECT count(*) FROM sqlite_master WHERE type = 'index' AND name = ?",
                    arguments: [index]
                )
                XCTAssertEqual(count, 1, "Missing index: \(index)")
            }
            
            // ✅ Check columns for `entities`
            let entityColumns = try db.columns(in: "entities").map(\.name)
            let expectedEntityColumns = [
                "id", "type", "groupName", "tags", "payload", "createdAt", "createdBy",
                "updatedAt", "updatedBy", "sharedWith"
            ]
            for col in expectedEntityColumns {
                XCTAssertTrue(entityColumns.contains(col), "Missing column in entities: \(col)")
            }

            // ✅ Check columns for `relationships`
            let relColumns = try db.columns(in: "relationships").map(\.name)
            let expectedRelColumns = [
                "id", "type", "fromId", "toId", "payload", "createdAt", "createdBy",
                "updatedAt", "updatedBy", "tags", "groupName", "sharedWith", "permissions"
            ]
            for col in expectedRelColumns {
                XCTAssertTrue(relColumns.contains(col), "Missing column in relationships: \(col)")
            }

        }
    }
}

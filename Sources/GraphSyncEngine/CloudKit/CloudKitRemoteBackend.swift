//
//  CloudKitRemoteBackend.swift
//  GraphNext
//
//  Created by Valerio Buriani on 12/08/25.
//

import Foundation
import CloudKit
import GraphNext

public final class CloudKitRemoteBackend: RemoteSyncBackend {
    private let container: CKContainer
    private var database: CKDatabase { container.privateCloudDatabase }

    public init(container: CKContainer) {
        self.container = container
    }

    // MARK: - Fetch
    public func fetchEntities() async throws -> [Entity] {
        let records = try await fetchRecords(ofType: "Entity")
        return records.compactMap { Entity(from: $0) }
    }

    public func fetchRelationships() async throws -> [Relationship] {
        let records = try await fetchRecords(ofType: "Relationship")
        return records.compactMap { Relationship(from: $0) }
    }

    // MARK: - Save
    public func save(entities: [Entity]) async throws {
        for e in entities {
            try await saveRecord(e.asCKRecord())
        }
    }

    public func save(relationships: [Relationship]) async throws {
        for r in relationships {
            try await saveRecord(r.asCKRecord())
        }
    }

    public func resetRemote() async throws {
        // opzionale: implementare se vorrai supportare hard-reset lato backend
    }

    // MARK: - CloudKit helpers (iOS 15+ APIs, no deprecated blocks)
    private func fetchRecords(ofType type: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: type, predicate: predicate)

        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?

        repeat {
            let operation: CKQueryOperation = {
                if let c = cursor { return CKQueryOperation(cursor: c) }
                else { return CKQueryOperation(query: query) }
            }()

            var fetched: [CKRecord] = []
            operation.recordMatchedBlock = { _, result in
                if case .success(let record) = result {
                    fetched.append(record)
                } else if case .failure(let error) = result {
                    // logging discreto; non falliamo l'intera pagina
                    print("CloudKitRemoteBackend: record error: \(error)")
                }
            }

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.queryResultBlock = { result in
                    switch result {
                    case .success(let nextCursor):
                        cursor = nextCursor
                        allRecords.append(contentsOf: fetched)
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                self.database.add(operation)
            }
        } while cursor != nil

        return allRecords
    }

    private func saveRecord(_ record: CKRecord) async throws {
        _ = try await database.save(record)
    }
}

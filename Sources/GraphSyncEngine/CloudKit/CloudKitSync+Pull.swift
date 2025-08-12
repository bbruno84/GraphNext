//
//  CloudKitSync+Pull.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//
import Foundation
import CloudKit
import GraphNext

extension CloudKitSync {
    public func pull() async throws {
        let entityRecords = try await fetchRecords(ofType: "Entity")
        let relationshipRecords = try await fetchRecords(ofType: "Relationship")
        
        let entities = entityRecords.compactMap { Entity(from: $0) }
        let relationships = relationshipRecords.compactMap { Relationship(from: $0) }

        for entity in entities {
            store.add(entity)
        }

        for relationship in relationships {
            store.add(relationship)
        }
    }

    private func fetchRecords(ofType type: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: type, predicate: predicate)

        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?

        repeat {
            let operation: CKQueryOperation
            if let existingCursor = cursor {
                operation = CKQueryOperation(cursor: existingCursor)
            } else {
                operation = CKQueryOperation(query: query)
            }

            var fetchedRecords: [CKRecord] = []
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    fetchedRecords.append(record)
                case .failure(let error):
                    // Puoi loggare o ignorare, in base alla strategia del progetto
                    print("❗️Errore nel fetch di record \(recordID): \(error)")
                }
            }


            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.queryResultBlock = { result in
                    switch result {
                    case .success(let newCursor):
                        cursor = newCursor
                        allRecords.append(contentsOf: fetchedRecords)
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }


                container.privateCloudDatabase.add(operation)
            }

        } while cursor != nil

        return allRecords
    }
}

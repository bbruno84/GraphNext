//
//  CKRecord+GraphNext.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import CloudKit
import Foundation

extension Entity {
    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Entity", recordID: CKRecord.ID(recordName: self.id.uuidString))
        record["uuid"] = self.id.uuidString as CKRecordValue
        record["type"] = self.type as CKRecordValue
        
        if let payloadData = try? JSONEncoder().encode(self.payload) {
            record["payload"] = payloadData as CKRecordValue
        }
        
        // Attach CKAsset for file-backed assets, if a local URL is available.
        if self.type == "asset" {
            if let fileURL = try? AssetStorageProvider.shared.storage.urlIfPresent(assetId: self.id) {
                record["file"] = CKAsset(fileURL: fileURL)
            }
        }
        
        record["sharedWith"] = self.sharedWith as CKRecordValue
        
        record["createdBy"] = self.created.by as CKRecordValue
        record["createdAt"] = self.created.at as CKRecordValue
        
        if let updated = self.updated {
            record["updatedBy"] = updated.by as CKRecordValue
            record["updatedAt"] = updated.at as CKRecordValue
        }
        
        return record
    }
}

extension Relationship {
    func asCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Relationship", recordID: CKRecord.ID(recordName: self.id.uuidString))
        record["uuid"] = self.id.uuidString as CKRecordValue
        record["type"] = self.type as CKRecordValue
        
        if let from = self.from {
            record["sourceUUID"] = from.uuidString as CKRecordValue
        }
        if let to = self.to {
            record["targetUUID"] = to.uuidString as CKRecordValue
        }
        
        record["sharedWith"] = self.sharedWith as CKRecordValue
        
        record["createdBy"] = self.created.by as CKRecordValue
        record["createdAt"] = self.created.at as CKRecordValue
        
        if let updated = self.updated {
            record["updatedBy"] = updated.by as CKRecordValue
            record["updatedAt"] = updated.at as CKRecordValue
        }
        
        return record
    }
}

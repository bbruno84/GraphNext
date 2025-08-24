//
//  AssetMetadata.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//

import Foundation

/// Metadati minimi salvati nel payload di una `Entity` con `type: "asset"`.
/// Usati da AssetStorage e da tutti i backend (GRDB/CoreData/CloudKit).
public struct AssetMetadata: Codable, Equatable, Sendable {
    public let length: Int
    public let sha256: String
    public let mimeType: String
    public let fileName: String?

    public init(length: Int, sha256: String, mimeType: String, fileName: String? = nil) {
        self.length = length
        self.sha256 = sha256
        self.mimeType = mimeType
        self.fileName = fileName
    }
}

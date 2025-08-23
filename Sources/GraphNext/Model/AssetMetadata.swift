//
//  AssetMetadata.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//


import Foundation

public struct AssetMetadata: Equatable {
    public let length: Int
    public let sha256: String
    public let mimeType: String?
    public let fileName: String?

    public init(length: Int, sha256: String, mimeType: String?, fileName: String?) {
        self.length = length
        self.sha256 = sha256
        self.mimeType = mimeType
        self.fileName = fileName
    }
}
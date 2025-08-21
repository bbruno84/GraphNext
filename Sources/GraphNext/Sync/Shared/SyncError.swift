//
//  SyncError.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/08/25.
//
import Foundation

public enum SyncError: Error, Equatable {
    case notAuthenticated
    case network
    case rateLimited
    case invalidData
    case backend(String)
}

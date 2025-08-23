//
//  GraphPersistenceFactory.swift
//  GraphNext
//
//  Created by Valerio Buriani on 23/08/25.
//


//
//  GraphPersistenceFactory.swift
//  GraphNext
//
//  Created by Regia GraphNext on 23/08/2025.
//

import Foundation

public enum GraphPersistenceFactory {
    
    public static func makePersistence(
        kind: GraphNextConfig.PersistenceKind,
        databaseName: String,
        inMemory: Bool = false
    ) -> GraphPersistenceController {
        switch kind {
        case .grdb:
            fatalError("GRDBGraphPersistenceController non ancora implementato")
        case .coreData:
            fatalError("CoreDataGraphPersistenceController non ancora implementato")
        }
    }
}
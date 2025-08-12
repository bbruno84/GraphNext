//
//  CloudkitSync.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation
import CloudKit
import GraphPersistence
import GraphNext

public final class CloudKitSync: GraphSyncEngine {

    internal let persistence: GraphPersistenceController
    internal let store: GraphStore
    internal let container: CKContainer
    internal let database: CKDatabase
    
    public init(
        persistence: GraphPersistenceController,
        store: GraphStore,
        container: CKContainer = .default()
    ) {
        self.persistence = persistence
        self.store = store
        self.container = container
        self.database = container.privateCloudDatabase
    }
}



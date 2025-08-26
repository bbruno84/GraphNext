# Repository Tree

_Link relativi (branch-agnostici). Aggiornato automaticamente dalla CI._

## Table of Contents

- [LICENSE](#license)
- [Package.resolved](#package-resolved)
- [Package.swift](#package-swift)
- [README.md](#readme-md)
- [Docs/](#docs)
- [Scripts/](#scripts)
- [Sources/](#sources)
- [Tests/](#tests)

## LICENSE
- [LICENSE](../LICENSE)

## Package.resolved
- [Package.resolved](../Package.resolved)

## Package.swift
- [Package.swift](../Package.swift)

## README.md
- [README.md](../README.md)

## Docs/
- **[Docs/](../Docs)**
├── [Docs/AssetsFileBacked.md](../Docs/AssetsFileBacked.md)
├── [Docs/CloudKitSync.md](../Docs/CloudKitSync.md)
├── [Docs/GRDBGraphPersistenceController.md](../Docs/GRDBGraphPersistenceController.md)
├── [Docs/InitQuickStart.md](../Docs/InitQuickStart.md)

## Scripts/
- **[Scripts/](../Scripts)**
├── [Scripts/compile_coredata_model.sh](../Scripts/compile_coredata_model.sh)
├── [Scripts/generate_repo_tree.sh](../Scripts/generate_repo_tree.sh)

## Sources/
- **[Sources/](../Sources)**
└── **Sources/GraphNext/**
    ├── **Sources/GraphNext/Init/**
    │   ├── [Sources/GraphNext/Init/GraphNext.swift](../Sources/GraphNext/Init/GraphNext.swift)
    │   ├── [Sources/GraphNext/Init/GraphNextConfigKeys.swift](../Sources/GraphNext/Init/GraphNextConfigKeys.swift)
    ├── **Sources/GraphNext/Model/**
    │   ├── [Sources/GraphNext/Model/AssetMetadata.swift](../Sources/GraphNext/Model/AssetMetadata.swift)
    │   ├── [Sources/GraphNext/Model/AuditInfo.swift](../Sources/GraphNext/Model/AuditInfo.swift)
    │   ├── [Sources/GraphNext/Model/Entity.swift](../Sources/GraphNext/Model/Entity.swift)
    │   ├── [Sources/GraphNext/Model/GraphNode.swift](../Sources/GraphNext/Model/GraphNode.swift)
    │   ├── [Sources/GraphNext/Model/GraphPayload+DatabaseValueConvertible.swift](../Sources/GraphNext/Model/GraphPayload+DatabaseValueConvertible.swift)
    │   ├── [Sources/GraphNext/Model/GraphPayload.swift](../Sources/GraphNext/Model/GraphPayload.swift)
    │   ├── [Sources/GraphNext/Model/Permissions.swift](../Sources/GraphNext/Model/Permissions.swift)
    │   ├── [Sources/GraphNext/Model/Relationship.swift](../Sources/GraphNext/Model/Relationship.swift)
    ├── **Sources/GraphNext/Persistence/**
    │   ├── [Sources/GraphNext/Persistence/GraphPersistenceController.swift](../Sources/GraphNext/Persistence/GraphPersistenceController.swift)
    │   ├── [Sources/GraphNext/Persistence/GraphPersistenceFactory.swift](../Sources/GraphNext/Persistence/GraphPersistenceFactory.swift)
    │   ├── **Sources/GraphNext/Persistence/Assets/**
    │   │   ├── [Sources/GraphNext/Persistence/Assets/AssetService.swift](../Sources/GraphNext/Persistence/Assets/AssetService.swift)
    │   │   ├── [Sources/GraphNext/Persistence/Assets/AssetStorage.swift](../Sources/GraphNext/Persistence/Assets/AssetStorage.swift)
    │   │   ├── [Sources/GraphNext/Persistence/Assets/AssetStorageProvider.swift](../Sources/GraphNext/Persistence/Assets/AssetStorageProvider.swift)
    │   │   ├── [Sources/GraphNext/Persistence/Assets/FileAssetStorage.swift](../Sources/GraphNext/Persistence/Assets/FileAssetStorage.swift)
    │   │   ├── [Sources/GraphNext/Persistence/Assets/LRUAssetIndex.swift](../Sources/GraphNext/Persistence/Assets/LRUAssetIndex.swift)
    │   ├── **Sources/GraphNext/Persistence/CoreData/**
    │   │   ├── [Sources/GraphNext/Persistence/CoreData/CoreDataGraphPersistenceController+Assets.swift](../Sources/GraphNext/Persistence/CoreData/CoreDataGraphPersistenceController+Assets.swift)
    │   │   ├── [Sources/GraphNext/Persistence/CoreData/CoreDataGraphPersistenceController.swift](../Sources/GraphNext/Persistence/CoreData/CoreDataGraphPersistenceController.swift)
    │   │   ├── **Sources/GraphNext/Persistence/CoreData/Mapping/**
    │   │   │   ├── [Sources/GraphNext/Persistence/CoreData/Mapping/CDEntity+Mapping.swift](../Sources/GraphNext/Persistence/CoreData/Mapping/CDEntity+Mapping.swift)
    │   │   │   ├── [Sources/GraphNext/Persistence/CoreData/Mapping/CDRelationship+Mapping.swift](../Sources/GraphNext/Persistence/CoreData/Mapping/CDRelationship+Mapping.swift)
    │   │   └── **Sources/GraphNext/Persistence/CoreData/Model/**
    │   │       ├── [Sources/GraphNext/Persistence/CoreData/Model/CDEntity.swift](../Sources/GraphNext/Persistence/CoreData/Model/CDEntity.swift)
    │   │       ├── [Sources/GraphNext/Persistence/CoreData/Model/CDRelationship.swift](../Sources/GraphNext/Persistence/CoreData/Model/CDRelationship.swift)
    │   ├── **Sources/GraphNext/Persistence/GRDB/**
    │   │   ├── [Sources/GraphNext/Persistence/GRDB/GRDBGraphPersistenceController+Assets.swift](../Sources/GraphNext/Persistence/GRDB/GRDBGraphPersistenceController+Assets.swift)
    │   │   ├── [Sources/GraphNext/Persistence/GRDB/GRDBGraphPersistenceController+Queries.swift](../Sources/GraphNext/Persistence/GRDB/GRDBGraphPersistenceController+Queries.swift)
    │   │   ├── [Sources/GraphNext/Persistence/GRDB/GRDBGraphPersistenceController.swift](../Sources/GraphNext/Persistence/GRDB/GRDBGraphPersistenceController.swift)
    │   │   ├── [Sources/GraphNext/Persistence/GRDB/Migrations.swift](../Sources/GraphNext/Persistence/GRDB/Migrations.swift)
    │   │   ├── [Sources/GraphNext/Persistence/GRDB/Schema.swift](../Sources/GraphNext/Persistence/GRDB/Schema.swift)
    │   └── **Sources/GraphNext/Persistence/Resources/**
    │       ├── **Sources/GraphNext/Persistence/Resources/Compiled/**
    │       │   └── **Sources/GraphNext/Persistence/Resources/Compiled/GraphNext.momd/**
    │       │       ├── [Sources/GraphNext/Persistence/Resources/Compiled/GraphNext.momd/Model.mom](../Sources/GraphNext/Persistence/Resources/Compiled/GraphNext.momd/Model.mom)
    │       │       ├── [Sources/GraphNext/Persistence/Resources/Compiled/GraphNext.momd/VersionInfo.plist](../Sources/GraphNext/Persistence/Resources/Compiled/GraphNext.momd/VersionInfo.plist)
    │       └── **Sources/GraphNext/Persistence/Resources/GraphNext.xcdatamodeld/**
    │           └── **Sources/GraphNext/Persistence/Resources/GraphNext.xcdatamodeld/Model.xcdatamodel/**
    │               ├── [Sources/GraphNext/Persistence/Resources/GraphNext.xcdatamodeld/Model.xcdatamodel/contents](../Sources/GraphNext/Persistence/Resources/GraphNext.xcdatamodeld/Model.xcdatamodel/contents)
    ├── **Sources/GraphNext/Store/**
    │   ├── [Sources/GraphNext/Store/GraphStore.swift](../Sources/GraphNext/Store/GraphStore.swift)
    ├── **Sources/GraphNext/Sync/**
    │   ├── **Sources/GraphNext/Sync/CloudKit/**
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CKRecord+GraphNext.swift](../Sources/GraphNext/Sync/CloudKit/CKRecord+GraphNext.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CKRecord+Init.swift](../Sources/GraphNext/Sync/CloudKit/CKRecord+Init.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CKSyncEngineBackend.swift](../Sources/GraphNext/Sync/CloudKit/CKSyncEngineBackend.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CloudKitAttachmentPolicy.swift](../Sources/GraphNext/Sync/CloudKit/CloudKitAttachmentPolicy.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CloudKitSync+Assets.swift](../Sources/GraphNext/Sync/CloudKit/CloudKitSync+Assets.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CloudKitSync+Pull.swift](../Sources/GraphNext/Sync/CloudKit/CloudKitSync+Pull.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CloudKitSync+Reset.swift](../Sources/GraphNext/Sync/CloudKit/CloudKitSync+Reset.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CloudKitSync+Sync.swift](../Sources/GraphNext/Sync/CloudKit/CloudKitSync+Sync.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CloudKitSync.swift](../Sources/GraphNext/Sync/CloudKit/CloudKitSync.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CloudKitSyncConfig.swift](../Sources/GraphNext/Sync/CloudKit/CloudKitSyncConfig.swift)
    │   │   ├── [Sources/GraphNext/Sync/CloudKit/CloudKitTestHooks.swift](../Sources/GraphNext/Sync/CloudKit/CloudKitTestHooks.swift)
    │   ├── **Sources/GraphNext/Sync/Config/**
    │   │   ├── [Sources/GraphNext/Sync/Config/GraphSyncEngineFactory.swift](../Sources/GraphNext/Sync/Config/GraphSyncEngineFactory.swift)
    │   │   ├── [Sources/GraphNext/Sync/Config/SyncBackendKind.swift](../Sources/GraphNext/Sync/Config/SyncBackendKind.swift)
    │   ├── **Sources/GraphNext/Sync/Core/**
    │   │   ├── [Sources/GraphNext/Sync/Core/GraphSyncEngine.swift](../Sources/GraphNext/Sync/Core/GraphSyncEngine.swift)
    │   └── **Sources/GraphNext/Sync/Shared/**
    │       ├── [Sources/GraphNext/Sync/Shared/GraphStoreSyncAdapter.swift](../Sources/GraphNext/Sync/Shared/GraphStoreSyncAdapter.swift)
    │       ├── [Sources/GraphNext/Sync/Shared/RemoteSyncBackend.swift](../Sources/GraphNext/Sync/Shared/RemoteSyncBackend.swift)
    │       ├── [Sources/GraphNext/Sync/Shared/SyncError.swift](../Sources/GraphNext/Sync/Shared/SyncError.swift)
    └── **Sources/GraphNext/Utils/**
        ├── [Sources/GraphNext/Utils/Box.swift](../Sources/GraphNext/Utils/Box.swift)

## Tests/
- **[Tests/](../Tests)**
└── **Tests/GraphNextTests/**
    ├── [Tests/GraphNextTests/GraphNextE2ETests.swift](../Tests/GraphNextTests/GraphNextE2ETests.swift)
    ├── [Tests/GraphNextTests/GraphNextTests.swift](../Tests/GraphNextTests/GraphNextTests.swift)
    ├── **Tests/GraphNextTests/Assets/**
    │   ├── [Tests/GraphNextTests/Assets/AssetEvictionLRUTests.swift](../Tests/GraphNextTests/Assets/AssetEvictionLRUTests.swift)
    │   ├── [Tests/GraphNextTests/Assets/CoreDataFileBackedAssetsTests.swift](../Tests/GraphNextTests/Assets/CoreDataFileBackedAssetsTests.swift)
    │   ├── [Tests/GraphNextTests/Assets/FileAssetStorageTests.swift](../Tests/GraphNextTests/Assets/FileAssetStorageTests.swift)
    │   ├── [Tests/GraphNextTests/Assets/GRDBFileBackedAssetsTests.swift](../Tests/GraphNextTests/Assets/GRDBFileBackedAssetsTests.swift)
    │   ├── [Tests/GraphNextTests/Assets/GRDBGraphPersistenceController+AssetsTests.swift](../Tests/GraphNextTests/Assets/GRDBGraphPersistenceController+AssetsTests.swift)
    ├── **Tests/GraphNextTests/Init/**
    │   ├── [Tests/GraphNextTests/Init/GraphNextInitTests.swift](../Tests/GraphNextTests/Init/GraphNextInitTests.swift)
    ├── **Tests/GraphNextTests/Persistence/**
    │   ├── [Tests/GraphNextTests/Persistence/GRDBGraphPersistenceConcurrencyTests.swift](../Tests/GraphNextTests/Persistence/GRDBGraphPersistenceConcurrencyTests.swift)
    │   ├── [Tests/GraphNextTests/Persistence/GRDBMigrationTests.swift](../Tests/GraphNextTests/Persistence/GRDBMigrationTests.swift)
    │   ├── [Tests/GraphNextTests/Persistence/GRDBRelationshipQueryTests.swift](../Tests/GraphNextTests/Persistence/GRDBRelationshipQueryTests.swift)
    │   ├── [Tests/GraphNextTests/Persistence/GraphPersistenceControllerTests.swift](../Tests/GraphNextTests/Persistence/GraphPersistenceControllerTests.swift)
    ├── **Tests/GraphNextTests/Store/**
    │   ├── [Tests/GraphNextTests/Store/GraphStoreCacheTests.swift](../Tests/GraphNextTests/Store/GraphStoreCacheTests.swift)
    │   ├── [Tests/GraphNextTests/Store/GraphStoreObservableTests.swift](../Tests/GraphNextTests/Store/GraphStoreObservableTests.swift)
    │   ├── [Tests/GraphNextTests/Store/GraphStoreTests.swift](../Tests/GraphNextTests/Store/GraphStoreTests.swift)
    │   ├── [Tests/GraphNextTests/Store/GraphStoreUpdateTests.swift](../Tests/GraphNextTests/Store/GraphStoreUpdateTests.swift)
    └── **Tests/GraphNextTests/Sync/**
        ├── [Tests/GraphNextTests/Sync/AutoPushTests.swift](../Tests/GraphNextTests/Sync/AutoPushTests.swift)
        ├── [Tests/GraphNextTests/Sync/CloudKitAssetThresholdTests.swift](../Tests/GraphNextTests/Sync/CloudKitAssetThresholdTests.swift)
        ├── [Tests/GraphNextTests/Sync/CloudKitAssetsMapperTests.swift](../Tests/GraphNextTests/Sync/CloudKitAssetsMapperTests.swift)
        ├── [Tests/GraphNextTests/Sync/CloudKitAssetsOnDemandTests.swift](../Tests/GraphNextTests/Sync/CloudKitAssetsOnDemandTests.swift)
        ├── [Tests/GraphNextTests/Sync/DebounceTests.swift](../Tests/GraphNextTests/Sync/DebounceTests.swift)
        ├── [Tests/GraphNextTests/Sync/DeletionOrderAndNoLoopTests.swift](../Tests/GraphNextTests/Sync/DeletionOrderAndNoLoopTests.swift)
        ├── [Tests/GraphNextTests/Sync/DeltaDeletionTests.swift](../Tests/GraphNextTests/Sync/DeltaDeletionTests.swift)
        ├── [Tests/GraphNextTests/Sync/PullFlowTests.swift](../Tests/GraphNextTests/Sync/PullFlowTests.swift)
        ├── [Tests/GraphNextTests/Sync/PushFlowTests.swift](../Tests/GraphNextTests/Sync/PushFlowTests.swift)
        ├── [Tests/GraphNextTests/Sync/RemoteNotificationTests.swift](../Tests/GraphNextTests/Sync/RemoteNotificationTests.swift)
        ├── [Tests/GraphNextTests/Sync/ResetFlowTests.swift](../Tests/GraphNextTests/Sync/ResetFlowTests.swift)
        ├── [Tests/GraphNextTests/Sync/RetryBackoffTests.swift](../Tests/GraphNextTests/Sync/RetryBackoffTests.swift)
        ├── [Tests/GraphNextTests/Sync/SyncLogicTests.swift](../Tests/GraphNextTests/Sync/SyncLogicTests.swift)
        └── **Tests/GraphNextTests/Sync/Mock/**
            ├── [Tests/GraphNextTests/Sync/Mock/MockRemoteBackend.swift](../Tests/GraphNextTests/Sync/Mock/MockRemoteBackend.swift)
            ├── [Tests/GraphNextTests/Sync/Mock/TransientErrorMockBackend.swift](../Tests/GraphNextTests/Sync/Mock/TransientErrorMockBackend.swift)


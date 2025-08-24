//
//  AssetStorageProvider.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/25.
//


//
//  AssetStorageProvider.swift
//  GraphNext
//
//  Created by Regia GraphNext on 24/08/2025.
//

import Foundation

/// Registry minimale per fornire un AssetStorage globale
/// senza toccare i costruttori dei controller esistenti.
/// In PR successive verrà “agganciato” a GraphNextConfig.
public final class AssetStorageProvider: @unchecked Sendable {
    public static let shared = AssetStorageProvider()

    private var _storage: AssetStorage?
    private let lock = NSLock()

    public func setStorage(_ storage: AssetStorage) {
        lock.lock(); defer { lock.unlock() }
        _storage = storage
    }

    public var storage: AssetStorage {
        lock.lock(); defer { lock.unlock() }
        if let s = _storage { return s }
        // default lazy
        let url = (try? FileAssetStorage.makeDefaultBaseDirectory()) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let fileStore = (try? FileAssetStorage(baseDirectory: url)) ?? (try! FileAssetStorage(baseDirectory: URL(fileURLWithPath: NSTemporaryDirectory())))
        _storage = fileStore
        return fileStore
    }
}
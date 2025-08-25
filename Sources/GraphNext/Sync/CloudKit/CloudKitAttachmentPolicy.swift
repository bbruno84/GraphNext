//
//  CloudKitAttachmentPolicy.swift
//  GraphNext
//
//  Created by Valerio Buriani on 25/08/25.
//

import Foundation

/// Policy globale e banalissima per decidere se allegare il file al CKRecord.
/// CloudKitSync setterà questa soglia leggendo `configuration.assetThresholdBytes`.
enum CloudKitAttachmentPolicy {
    private static var _thresholdBytes: Int = 15 * 1024 * 1024 // default 15 MB

    static func setThresholdBytes(_ bytes: Int) {
        _thresholdBytes = max(0, bytes)
    }

    static var thresholdBytes: Int { _thresholdBytes }
}

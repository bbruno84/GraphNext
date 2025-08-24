//
//  CloudKitTestHooks.swift
//  GraphNext
//
//  Created by Valerio Buriani on 24/08/25.
//


import Foundation
import CloudKit

/// Test hooks per permettere ai test di iniettare risposte finte da CloudKit
/// senza andare in rete o dover subclassare tipi di CloudKit.
enum CloudKitTestHooks {
    /// Se impostata, `CloudKitSync.fetchAssetIfNeeded` userà questa closure
    /// per ottenere un CKRecord per l’asset richiesto invece di contattare CloudKit.
    static var fetchAssetRecord: ((UUID) -> CKRecord?)?
}

//
//  CDEntity.swift
//  GraphNext
//
//  Created by Valerio Buriani on 25/08/25.
//


import Foundation
import CoreData

@objc(CDEntity)
public final class CDEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDEntity> {
        return NSFetchRequest<CDEntity>(entityName: "CDEntity")
    }

    // MARK: - Attributi (derivati da Model.xcdatamodel)
    @NSManaged public var id: UUID                       // UUID (non-optional nel modello)
    @NSManaged public var type: String                   // String (non-optional)

    // Binary
    @NSManaged public var created: Data?                 // Binary (optional)
    @NSManaged public var payload: Data?                 // Binary (optional)
    @NSManaged public var permissions: Data?             // Binary (optional)
    @NSManaged public var properties: Data?              // Binary (optional, allowsExternalBinaryDataStorage)
    @NSManaged public var updatedAt: Data?               // Binary (optional)

    // Transformable con transformer sicuro
    @NSManaged public var group: NSSet?                  // Transformable (NSSet) optional
    @NSManaged public var sharedWith: NSArray?           // Transformable (NSArray) optional
    @NSManaged public var tag: NSSet?                    // Transformable (NSSet) optional

    // Numerico
    @NSManaged public var version: Int64                 // Integer 64 (optional nel modello, default 0)
}
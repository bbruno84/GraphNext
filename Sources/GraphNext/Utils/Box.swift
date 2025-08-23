//
//  Box.swift
//  GraphNext
//
//  Created by Valerio Buriani on 21/08/25.
//


import Foundation

public final class Box<T: AnyObject>: NSObject {
    public let value: T
    
    public init(_ value: T) {
        self.value = value
    }
}
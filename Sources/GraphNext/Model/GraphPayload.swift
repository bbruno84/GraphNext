//
//  GraphPayload.swift
//  GraphNext
//
//  Created by Valerio Buriani on 19/07/25.
//

import Foundation

/// Un singolo valore supportato dal dizionario payload.
public enum GraphPayloadValue: Codable, Equatable {
    case string(String)
    case double(Double)
    case int(Int)
    case bool(Bool)
    case date(Date)

    enum CodingKeys: String, CodingKey {
        case type, value
    }

    enum ValueType: String, Codable {
        case string, double, int, bool, date
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        switch type {
        case .string:
            self = .string(try container.decode(String.self, forKey: .value))
        case .double:
            self = .double(try container.decode(Double.self, forKey: .value))
        case .int:
            self = .int(try container.decode(Int.self, forKey: .value))
        case .bool:
            self = .bool(try container.decode(Bool.self, forKey: .value))
        case .date:
            self = .date(try container.decode(Date.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let value):
            try container.encode(ValueType.string, forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode(ValueType.double, forKey: .type)
            try container.encode(value, forKey: .value)
        case .int(let value):
            try container.encode(ValueType.int, forKey: .type)
            try container.encode(value, forKey: .value)
        case .bool(let value):
            try container.encode(ValueType.bool, forKey: .type)
            try container.encode(value, forKey: .value)
        case .date(let value):
            try container.encode(ValueType.date, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

/// Dizionario di valori payload associabili a un nodo del grafo.
/// È serializzabile e serve per contenere i dati esterni all'indice.
public typealias GraphPayload = [String: GraphPayloadValue]


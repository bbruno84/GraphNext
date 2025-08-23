import GRDB

extension GraphPayloadValue: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        switch self {
        case .string(let value): return value.databaseValue
        case .int(let value): return value.databaseValue
        case .double(let value): return value.databaseValue
        case .bool(let value): return (value ? 1 : 0).databaseValue
        case .date(let value): return value.timeIntervalSince1970.databaseValue
        }
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> GraphPayloadValue? {
        // Decoding is not needed in our context, but required by the protocol.
        return nil
    }
}
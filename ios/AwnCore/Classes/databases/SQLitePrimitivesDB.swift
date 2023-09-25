//
//  UserDefaultPrimitivesDB.swift
//  IosAwnCore
//
//  Created by Rafael Setragni on 18/02/23.
//

import Foundation
import SQLite3

public enum SQLiteError: Error {
    case openFailed(String)
    case queryFailed(String)
    case invalidParameterType
    case notFound
}

public class SQLitePrimitivesDB {
    
    private var DATABASE_VERSION = 1
    private var DATABASE_NAME = "AwesomePrimitivesDB.db"

    private var TABLE_STRING = "string_prefs"
    private var TABLE_INT = "int_prefs"
    private var TABLE_FLOAT = "float_prefs"
    private var TABLE_BOOLEAN = "boolean_prefs"
    private var TABLE_LONG = "long_prefs"
    private let COLUMN_TAG = "tag"
    private let COLUMN_KEY = "key"
    private let COLUMN_VALUE = "value"
    
    private let databasePath:URL
    private init() {
        databasePath = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(DATABASE_NAME)

        switch openDatabase(writable: true) {
            
            case .success(let db):
                onCreate(writableDb: db)
            
            case .failure(let error):
                print("Error opening database: \(error.localizedDescription)")
        }
    }
    static let shared = SQLitePrimitivesDB()

    private func openDatabase(writable: Bool) -> Result<OpaquePointer, SQLiteError> {
        var db: OpaquePointer?
        let flags = writable ? SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE : SQLITE_OPEN_READONLY

        return withUnsafeMutablePointer(to: &db) { dbPointer in
            let status = sqlite3_open_v2(databasePath.path, dbPointer, flags, nil)

            guard status == SQLITE_OK, let database = dbPointer.pointee else {
                let errorMessage = String(cString: sqlite3_errmsg(dbPointer.pointee))
                return .failure(SQLiteError.openFailed(errorMessage))
            }

            let copy = database
            return .success(copy)
        }
    }

    private func getWritableDatabase() -> Result<OpaquePointer, SQLiteError> {
        openDatabase(writable: true)
    }

    private func getReadableDatabase() -> Result<OpaquePointer, SQLiteError> {
        openDatabase(writable: false)
    }
    
    private func execute(db: OpaquePointer, query: String, parameters: (() -> [Any])? = nil) -> Result<OpaquePointer, SQLiteError> {
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return .failure(SQLiteError.queryFailed(String(cString: sqlite3_errmsg(db))))
        }

        if let parameters = parameters {
            let values = parameters()

            for (index, value) in values.enumerated() {
                let statementIndex = Int32(index + 1)

                switch value {
                case let int as Int:
                    sqlite3_bind_int(statement, statementIndex, Int32(int))

                case let int64 as Int64:
                    sqlite3_bind_int64(statement, statementIndex, int64)

                case let double as Double:
                    sqlite3_bind_double(statement, statementIndex, double)

                case let bool as Bool:
                    let intValue = bool ? 1 : 0
                    sqlite3_bind_int(statement, statementIndex, Int32(intValue))

                case let string as String:
                    let itemNSString = string as NSString
                    sqlite3_bind_text(statement, statementIndex, itemNSString.utf8String, -1, nil)

                default:
                    return .failure(SQLiteError.invalidParameterType)
                }
            }
        }

        let result = sqlite3_step(statement)
        
        if result == SQLITE_NOTFOUND {
            return .failure(SQLiteError.notFound)
        }
        
        if result == SQLITE_ROW {
            return .success(statement!)
        }
        
        if result == SQLITE_DONE {
            return .success(statement!)
        }
        
        return .failure(SQLiteError.queryFailed(String(cString: sqlite3_errmsg(db))))
    }

    
    private func onCreate(writableDb: OpaquePointer) {
        let createStringTable = """
            CREATE TABLE IF NOT EXISTS \(TABLE_STRING) (
                \(COLUMN_TAG) TEXT,
                \(COLUMN_KEY) TEXT,
                \(COLUMN_VALUE) TEXT,
                PRIMARY KEY (\(COLUMN_TAG), \(COLUMN_KEY)));
        """
        _ = execute(db: writableDb, query:createStringTable)

        let createIntTable = """
            CREATE TABLE IF NOT EXISTS \(TABLE_INT) (
                \(COLUMN_TAG) TEXT,
                \(COLUMN_KEY) TEXT,
                \(COLUMN_VALUE) INTEGER,
                PRIMARY KEY (\(COLUMN_TAG), \(COLUMN_KEY)));
        """
        _ = execute(db: writableDb, query:createIntTable)

        let createFloatTable = """
            CREATE TABLE IF NOT EXISTS \(TABLE_FLOAT) (
                \(COLUMN_TAG) TEXT,
                \(COLUMN_KEY) TEXT,
                \(COLUMN_VALUE) REAL,
                PRIMARY KEY (\(COLUMN_TAG), \(COLUMN_KEY)));
        """
        _ = execute(db: writableDb, query:createFloatTable)

        let createBooleanTable = """
            CREATE TABLE IF NOT EXISTS \(TABLE_BOOLEAN) (
                \(COLUMN_TAG) TEXT,
                \(COLUMN_KEY) TEXT,
                \(COLUMN_VALUE) INTEGER,
                PRIMARY KEY (\(COLUMN_TAG), \(COLUMN_KEY)));
        """
        _ = execute(db: writableDb, query:createBooleanTable)

        let createLongTable = """
            CREATE TABLE IF NOT EXISTS \(TABLE_LONG) (
                \(COLUMN_TAG) TEXT,
                \(COLUMN_KEY) TEXT,
                \(COLUMN_VALUE) INTEGER,
                PRIMARY KEY (\(COLUMN_TAG), \(COLUMN_KEY)));
        """
        _ = execute(db: writableDb, query:createLongTable)
    }
    
    private func commit(db: OpaquePointer){
        _ = execute(db: db, query: "COMMIT")
        close(db: db)
    }
    
    private func rollback(db: OpaquePointer){
        _ = execute(db: db, query: "ROLLBACK")
        close(db: db)
    }
    
    private func close(db: OpaquePointer){
        sqlite3_close(db)
    }
    
    private func setValue<T>(tableName: String, tag: String, key: String, value: T) -> Result<Void, SQLiteError> {
        let query = """
            INSERT OR REPLACE INTO \(tableName) (\(COLUMN_TAG), \(COLUMN_KEY), \(COLUMN_VALUE))
            VALUES (?, ?, ?)
        """

        let parameters = { [tag, key, value] as [Any] }

        switch getWritableDatabase() {
        case .success(let db):
            switch execute(db: db, query: query, parameters: parameters) {
            case .success:
                _ = execute(db: db, query: "COMMIT")
                close(db: db)
                return .success(())

            case .failure(let error):
                _ = execute(db: db, query: "ROLLBACK")
                close(db: db)
                print("Error setting value: \(error.localizedDescription)")
                return .failure(error)
            }

        case .failure(let error):
            print("Error getting writable database: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    public func setBoolean(tag: String, key: String, value: Bool) -> Result<Void, SQLiteError> {
        return setValue(tableName: TABLE_BOOLEAN, tag: tag, key: key, value: value ? 1 : 0)
    }
    public func setInt(tag: String, key: String, value: Int) -> Result<Void, SQLiteError> {
        return setValue(tableName: TABLE_INT, tag: tag, key: key, value: value)
    }
    public func setLong(tag: String, key: String, value: Int64) -> Result<Void, SQLiteError> {
        return setValue(tableName: TABLE_LONG, tag: tag, key: key, value: value)
    }
    public func setFloat(tag: String, key: String, value: Float) -> Result<Void, SQLiteError> {
        return setValue(tableName: TABLE_FLOAT, tag: tag, key: key, value: value)
    }
    public func setString(tag: String, key: String, value: String) -> Result<Void, SQLiteError> {
        return setValue(tableName: TABLE_STRING, tag: tag, key: key, value: value)
    }
    
    private func getValue<T>(tag: String, key: String, type: T.Type) -> Result<T?, SQLiteError> {
        let tableName: String
        switch type {
        case is Int.Type:
            tableName = TABLE_STRING

        case is Int64.Type:
            tableName = TABLE_STRING
            
        case is Double.Type:
            tableName = TABLE_STRING

        case is Float.Type:
            tableName = TABLE_STRING

        case is Bool.Type:
            tableName = TABLE_STRING

        case is String.Type:
            tableName = TABLE_STRING
            
        default:
            return .failure(SQLiteError.notFound)
        }
        
        let query = """
            SELECT \(COLUMN_VALUE) FROM \(tableName)
            WHERE \(COLUMN_TAG) = ? AND \(COLUMN_KEY) = ?
        """

        
        let parameters = { [tag, key] as [Any] }

        switch getReadableDatabase() {
        case .success(let db):
            defer { close(db: db) }
            
            switch execute(db: db, query: query, parameters: parameters) {
            case .success(let statement):
                defer { sqlite3_finalize(statement) }

                switch type {
                case is Int.Type:
                    let value = sqlite3_column_int(statement, 0)
                    return .success(value as? T)

                case is Int64.Type:
                    let value = sqlite3_column_int64(statement, 0)
                    return .success(value as? T)

                case is Double.Type:
                    let value = sqlite3_column_double(statement, 0)
                    return .success(value as? T)

                case is Float.Type:
                    let value = sqlite3_column_double(statement, 0)
                    return .success(value as? T)

                case is Bool.Type:
                    let value = sqlite3_column_int(statement, 0)
                    return .success((value == 1) as? T)

                case is String.Type:
                    let value = String(cString: sqlite3_column_text(statement, 0))
                    return .success(value as? T)

                default:
                    return .failure(SQLiteError.invalidParameterType)
                }

            case .failure(let error):
                switch error {
                case .notFound:
                    return .success(nil)
                default:
                    return .failure(error)
                }
                
            }

        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func getBoolean(tag: String, key: String) -> Result<Bool?, SQLiteError> {
        return getValue(tag: tag, key: key, type: Bool.self)
    }

    public func getInt(tag: String, key: String)  -> Result<Int?, SQLiteError> {
        return getValue(tag: tag, key: key, type: Int.self)
    }

    public func getLong(tag: String, key: String) -> Result<Int64?, SQLiteError> {
        return getValue(tag: tag, key: key, type: Int64.self)
    }

    public func getFloat(tag: String, key: String) -> Result<Float?, SQLiteError> {
        return getValue(tag: tag, key: key, type: Float.self)
    }

    public func getString(tag: String, key: String) -> Result<String?, SQLiteError> {
        return getValue(tag: tag, key: key, type: String.self)
    }

    
    private func count(tableName: String, tag: String) -> Result<Int, SQLiteError> {
        let query = """
            SELECT COUNT(*)
            FROM \(tableName)
            WHERE \(COLUMN_TAG) = ?
        """

        var count = 0
        switch getReadableDatabase() {
        case .success(let db):
            defer { close(db: db)}
            
            switch execute(db: db, query: query, parameters: { [tag] as [Any] }) {
            case .success(let statement):
                defer { sqlite3_finalize(statement) }
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(statement, 0))
                }
                return .success(count)

            case .failure(let error):
                return .failure(error)
            }

        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func stringCount(tag: String) -> Result<Int, SQLiteError> {
        return count(tableName: TABLE_STRING, tag: tag)
    }
    
    public func floatCount(tag: String) -> Result<Int, SQLiteError> {
        return count(tableName: TABLE_FLOAT, tag: tag)
    }

    public func intCount(tag: String) -> Result<Int, SQLiteError> {
        return count(tableName: TABLE_INT, tag: tag)
    }

    public func booleanCount(tag: String) -> Result<Int, SQLiteError> {
        return count(tableName: TABLE_BOOLEAN, tag: tag)
    }

    public func longCount(tag: String) -> Result<Int, SQLiteError> {
        return count(tableName: TABLE_LONG, tag: tag)
    }

    
    private func getAllValues<T>(tableName: String, tag: String, valueGetter: (OpaquePointer) -> T) -> Result<[String: T], SQLiteError> {
        var values: [String: T] = [:]

        let query = """
            SELECT \(COLUMN_KEY), \(COLUMN_VALUE) FROM \(tableName)
            WHERE \(COLUMN_TAG) = '\(tag)'
        """
        
        switch getReadableDatabase() {
        case .success(let db):
            defer { close(db: db)}
            
            switch execute(db: db, query: query, parameters: { [tag] as [Any] }) {
            case .success(let statement):
                defer { sqlite3_finalize(statement) }
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    let key = String(cString: sqlite3_column_text(statement, 0))
                    let value = valueGetter(statement)

                    values[key] = value
                }
                return .success(values)

            case .failure(let error):
                return .failure(error)
            }

        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func getAllStringValues(tag: String) -> Result<[String: String], SQLiteError> {
        getAllValues(tableName: TABLE_STRING, tag: tag) { statement in
            String(cString: sqlite3_column_text(statement, 1))
        }
    }

    public func getAllFloatValues(tag: String) -> Result<[String: Float], SQLiteError> {
        return getAllValues(tableName: TABLE_FLOAT, tag: tag) { statement in
            Float(sqlite3_column_double(statement, 1))
        }
    }

    public func getAllIntValues(tag: String) -> Result<[String: Int], SQLiteError> {
        return getAllValues(tableName: TABLE_INT, tag: tag) { statement in
            Int(sqlite3_column_int(statement, 1))
        }
    }

    public func getAllBooleanValues(tag: String) -> Result<[String: Bool], SQLiteError> {
        return getAllValues(tableName: TABLE_BOOLEAN, tag: tag) { statement in
            sqlite3_column_int(statement, 1) != 0
        }
    }

    public func getAllLongValues(tag: String) -> Result<[String: Int64], SQLiteError> {
        return getAllValues(tableName: TABLE_LONG, tag: tag) { statement in
            sqlite3_column_int64(statement, 1)
        }
    }
    
    private func setAllValues<T>(tableName: String, tag: String, values: [String: T]) -> Result<Void, SQLiteError> where T: Any {
        let query = """
            INSERT OR REPLACE INTO \(tableName) (\(COLUMN_TAG), \(COLUMN_KEY), \(COLUMN_VALUE))
            VALUES (?, ?, ?)
        """
        
        switch getWritableDatabase() {
        case .success(let db):
            defer { close(db: db)}
            
            _ = execute(db: db, query: "BEGIN TRANSACTION")
            
            for (key, value) in values {
                let parameters = [tag, key, value] as [Any]
                let _ = execute(db: db, query: query, parameters: { parameters })
            }
            
            _ = execute(db: db, query: "COMMIT")
            return .success(())
            
        case .failure(let error):
            return .failure(SQLiteError.queryFailed(
                "Error getting writable database: \(error.localizedDescription)"
            ))
        }
    }
    
    public func setAllIntValues(tag: String, intValues: [String: Int]) -> Result<Void, SQLiteError> {
        return setAllValues(tableName: TABLE_INT, tag: tag, values: intValues)
    }
    
    public func setAllStringValues(tag: String, stringValues: [String: String]) -> Result<Void, SQLiteError> {
        return setAllValues(tableName: TABLE_STRING, tag: tag, values: stringValues)
    }
    
    public func setAllFloatValues(tag: String, floatValues: [String: Float]) -> Result<Void, SQLiteError> {
        return setAllValues(tableName: TABLE_FLOAT, tag: tag, values: floatValues)
    }
    
    public func setAllBooleanValues(tag: String, booleanValues: [String: Bool]) -> Result<Void, SQLiteError> {
        return setAllValues(tableName: TABLE_BOOLEAN, tag: tag, values: booleanValues)
    }
    
    public func setAllLongValues(tag: String, longValues: [String: Int64]) -> Result<Void, SQLiteError> {
        return setAllValues(tableName: TABLE_LONG, tag: tag, values: longValues)
    }

    private func removeValue(tableName: String, tag: String, key: String) -> Result<Void, SQLiteError> {
        let query = """
            DELETE FROM \(tableName)
            WHERE \(COLUMN_TAG) = ? AND \(COLUMN_KEY) = ?
        """

        let parameters = { [tag, key] as [Any] }

        switch getWritableDatabase() {
        case .success(let db):
            defer { close(db: db)}
            
            switch execute(db: db, query: query, parameters: parameters) {
            case .success:
                _ = execute(db: db, query: "COMMIT")
                return .success(())

            case .failure(let error):
                _ = execute(db: db, query: "ROLLBACK")
                return .failure(SQLiteError.queryFailed(
                    "Error removing value: \(error.localizedDescription)"
                ))
            }

        case .failure(let error):
            return .failure(SQLiteError.queryFailed(
                "Error getting writable database: \(error.localizedDescription)"
            ))
        }
    }
    
    public func removeString(tag: String, key: String) -> Result<Void, SQLiteError> {
        return removeValue(tableName: TABLE_STRING, tag: tag, key: key)
    }

    public func removeFloat(tag: String, key: String) -> Result<Void, SQLiteError> {
        return removeValue(tableName: TABLE_FLOAT, tag: tag, key: key)
    }

    public func removeInt(tag: String, key: String) -> Result<Void, SQLiteError> {
        return removeValue(tableName: TABLE_INT, tag: tag, key: key)
    }

    public func removeBoolean(tag: String, key: String) -> Result<Void, SQLiteError> {
        return removeValue(tableName: TABLE_BOOLEAN, tag: tag, key: key)
    }

    public func removeLong(tag: String, key: String) -> Result<Void, SQLiteError> {
        return removeValue(tableName: TABLE_LONG, tag: tag, key: key)
    }

    private func removeAllValues(tableName: String, tag: String) -> Result<Void, SQLiteError> {
        let query = "DELETE FROM \(tableName) WHERE \(COLUMN_TAG) = ?"
        let parameters = { [tag] as [Any] }

        switch getWritableDatabase() {
        case .success(let db):
            defer { close(db: db)}
            
            switch execute(db: db, query: query, parameters: parameters) {
            case .success:
                _ = execute(db: db, query: "COMMIT")
                return .success(())

            case .failure(let error):
                _ = execute(db: db, query: "ROLLBACK")
                return .failure(SQLiteError.queryFailed(
                    "Error removing values: \(error.localizedDescription)"
                ))
            }
            
        case .failure(let error):
            return .failure(SQLiteError.queryFailed(
                "Error getting writable database: \(error.localizedDescription)"
            ))
        }
    }

    public func removeAllString(tag: String) -> Result<Void, SQLiteError> {
        return removeAllValues(tableName: TABLE_STRING, tag: tag)
    }

    public func removeAllFloat(tag: String) -> Result<Void, SQLiteError> {
        return removeAllValues(tableName: TABLE_FLOAT, tag: tag)
    }

    public func removeAllInt(tag: String) -> Result<Void, SQLiteError> {
        return removeAllValues(tableName: TABLE_INT, tag: tag)
    }

    public func removeAllBoolean(tag: String) -> Result<Void, SQLiteError> {
        return removeAllValues(tableName: TABLE_BOOLEAN, tag: tag)
    }

    public func removeAllLong(tag: String) -> Result<Void, SQLiteError> {
        return removeAllValues(tableName: TABLE_LONG, tag: tag)
    }

    private func removeAll(tableName: String, tag: String) -> Result<Void, SQLiteError> {
        let results: [Result<Void, SQLiteError>] = [
            removeAllString(tag: tag),
            removeAllInt(tag: tag),
            removeAllLong(tag: tag),
            removeAllFloat(tag: tag),
            removeAllBoolean(tag: tag)
        ]
        
        let firstFailure = results.first(where: { result in
            if case let .failure(error) = result {
                print("Error removing all values: \(error.localizedDescription)")
                return true
            }
            return false
        })
        
        if let firstFailure = firstFailure {
            return firstFailure
        }
        
        return .success(())
    }
}

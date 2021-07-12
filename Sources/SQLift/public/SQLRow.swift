import SQLite3
import struct Foundation.Data

/// Represents single data row fetched from the database.
///
/// Columns order is not preserved.
/// Access to members is dynamic,
/// if a row contains value for column named as given member name
/// it will be then casted or mapped to expected type if possible.
/// Keep in mind that some types i.e. Int and Bool
/// can both be decoded from same underlying value.
@dynamicMemberLookup
public struct SQLRow {

  /// All column names that are part of this row.
  /// Columns order is not preserved.
  public var columnNames: Set<String> { Set(values.keys) }

  private let values: Dictionary<String, SQLBindable?>

  internal init(
    _ handle: OpaquePointer?
  ) {
    func bindable(
      at index: Int32
    ) -> SQLBindable? {
      let columnType: Int32
        = sqlite3_column_type(
          handle,
          index
        )

      switch columnType {
      case SQLITE_BLOB:
        let pointer: UnsafeRawPointer?
          = sqlite3_column_blob(
            handle,
            index
          )

        if let pointer: UnsafeRawPointer = pointer {
          let length: Int
            = .init(
              sqlite3_column_bytes(
                handle,
                index
              )
            )
          return Data(
            bytes: pointer,
            count: length
          )
        } else {
          return Data()
        }

      case SQLITE_FLOAT:
        return sqlite3_column_double(
          handle,
          index
        )

      case SQLITE_INTEGER:
        return sqlite3_column_int64(
          handle,
          index
        )

      case SQLITE_NULL:
        return nil

      case SQLITE_TEXT:
        return String(
          cString: UnsafePointer(
            sqlite3_column_text(
              handle,
              index
            )
          )
        )

      case let type:
        fatalError(
          "Encountered unsupported SQLite column type: \(type)"
        )
      }
    }

    self.values = .init(
      uniqueKeysWithValues:
        (0 ..< sqlite3_column_count(handle))
        .map { columnIndex in
          (
            key: String(
              cString: sqlite3_column_name(
                handle,
                columnIndex
              )
            ),
            value: bindable(
              at: columnIndex
            )
          )
        }
    )
  }

  public subscript(
    dynamicMember column: String
  ) -> Data? {
    values[column] as? Data
  }

  public subscript(
    dynamicMember column: String
  ) -> String? {
    values[column] as? String
  }

  public subscript(
    dynamicMember column: String
  ) -> Int64? {
    values[column] as? Int64
  }

  public subscript(
    dynamicMember column: String
  ) -> Int? {
    (values[column] as? Int64)
      .map(Int.init)
  }

  public subscript(
    dynamicMember column: String
  ) -> Double? {
    values[column] as? Double
  }

  public subscript(
    dynamicMember column: String
  ) -> Bool? {
    (values[column] as? Int64)
      .map { $0 != 0 }
  }
}

extension SQLRow: CustomStringConvertible {

  public var description: String {
    """
    ---
    SQLRow
    \(
      values
        .map { key, value in
          "  \(key): \((value as Any?).map { "\($0)" } ?? "nil")"
        }
        .joined(separator: "\n")
    )
    ---
    """
  }
}

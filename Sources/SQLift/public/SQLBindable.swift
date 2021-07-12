import SQLite3
import struct Foundation.Data

/// Common protocol for all types that can become binded to ``SQLStatement``.
///
/// - Note: SQLift uses SQLite as database engine, all data types has to be compatible
/// with SQLite to work correctly.
///
/// Protocol is not intended to be used to implement custom bindings.
/// All types that are supported by SQLite
/// and can be translated to are already implemented.
/// SQLBindable is implemented by:
///   - ``Int``
///   - ``Int64``
///   - ``String``
///   - ``Bool``
///   - ``Double``
///   - ``Data``
public protocol SQLBindable {

  /// SQLift internal implementation detail.
  func bind(
    _ handle: OpaquePointer?,
    at index: Int32
  ) -> Bool
}

extension Int64: SQLBindable {

  public func bind(
    _ handle: OpaquePointer?,
    at index: Int32
  ) -> Bool {
    sqlite3_bind_int64(
      handle,
      index,
      self
    ) == SQLITE_OK
  }
}

extension Int: SQLBindable {

  public func bind(
    _ handle: OpaquePointer?,
    at index: Int32
  ) -> Bool {
    sqlite3_bind_int64(
      handle,
      index,
      Int64(self)
    ) == SQLITE_OK
  }
}

extension String: SQLBindable {

  public func bind(
    _ handle: OpaquePointer?,
    at index: Int32
  ) -> Bool {
    sqlite3_bind_text(
      handle,
      index,
      self,
      -1,
      SQLITE_TRANSIENT
    ) == SQLITE_OK
  }
}

extension Bool: SQLBindable {

  public func bind(
    _ handle: OpaquePointer?,
    at index: Int32
  ) -> Bool {
    sqlite3_bind_int(
      handle,
      index,
      self ? 1 : 0
    ) == SQLITE_OK
  }
}

extension Double: SQLBindable {

  public func bind(
    _ handle: OpaquePointer?,
    at index: Int32
  ) -> Bool {
    sqlite3_bind_double(
      handle,
      index,
      self
    ) == SQLITE_OK
  }
}

extension Data: SQLBindable {

  public func bind(
    _ handle: OpaquePointer?,
    at index: Int32
  ) -> Bool {
    sqlite3_bind_blob(
      handle,
      index,
      [UInt8](self),
      Int32(self.count),
      SQLITE_TRANSIENT
    ) == SQLITE_OK
  }
}

// https://sqlite.org/c3ref/c_static.html
private let SQLITE_TRANSIENT
  = unsafeBitCast(
    -1,
    to: sqlite3_destructor_type.self
  )

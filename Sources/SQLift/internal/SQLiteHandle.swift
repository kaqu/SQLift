import SQLite3

@usableFromInline
internal final class SQLiteConnectionHandle {

  internal static func open(
    at path: String,
    options: Int32
  ) throws -> Self {
    var handle: OpaquePointer?
    let openingStatus: Int32
      = sqlite3_open_v2(
        path,
        &handle,
        options,
        nil
      )

    guard openingStatus == SQLITE_OK
    else {
      let errorMessage: String
      if handle != nil {
        errorMessage
          = sqlite3_errmsg(handle)
          .map(String.init(cString:))
          ?? "Unable to open database at: \(path)"
        sqlite3_close(handle)
      } else {
        errorMessage = "Unable to open database at: \(path)"
      }
      throw SQLConnectionError(
        message: errorMessage
      )
    }

    return Self(handle)
  }

  private let handle: OpaquePointer?

  private init(
    _ handle: OpaquePointer?
  ) {
    self.handle = handle
  }

  deinit {
    sqlite3_close(handle)
  }

  @usableFromInline
  internal func execute(
    _ statement: SQLStatement,
    with parameters: Array<SQLBindable?> = .init()
  ) throws {
    let statementHandle: OpaquePointer?
      = try prepareStatement(
        statement,
        with: parameters
      )
    defer { sqlite3_finalize(statementHandle) }

    let stepResult: Int32
      = sqlite3_step(
        statementHandle
      )

    guard stepResult != SQLITE_ROW
    else {
      throw SQLExecutionError(
        message: "Statement execution method is not intended to load data, please use load instead."
      )
    }

    guard stepResult == SQLITE_DONE
    else {
      throw SQLExecutionError(
        message: lastErrorMessage()
      )
    }
  }

  @usableFromInline
  internal func fetch(
    _ statement: SQLStatement,
    with parameters: Array<SQLBindable?> = .init()
  ) throws -> Array<SQLRow> {
    let statementHandle: OpaquePointer?
      = try prepareStatement(
        statement,
        with: parameters
      )
    defer { sqlite3_finalize(statementHandle) }

    var rows: Array<SQLRow> = []
    var stepResult: Int32
      = sqlite3_step(
        statementHandle
      )

    while stepResult == SQLITE_ROW {
      rows
        .append(
          SQLRow(
            statementHandle
          )
        )
      stepResult
        = sqlite3_step(
          statementHandle
        )
    }

    guard stepResult == SQLITE_DONE
    else {
      throw SQLExecutionError(
        message: lastErrorMessage()
      )
    }

    return rows
  }


  @inline(__always)
  private func prepareStatement(
    _ statement: SQLStatement,
    with parameters: Array<SQLBindable?>
  ) throws -> OpaquePointer? {
    var statementHandle: OpaquePointer?

    let statementPreparationResult: Int32
      = sqlite3_prepare_v2(
        handle,
        statement.rawString,
        -1,
        &statementHandle,
        nil
      )

    guard statementPreparationResult == SQLITE_OK
    else {
      throw SQLStatementError(
        message: lastErrorMessage()
      )
    }

    guard sqlite3_bind_parameter_count(statementHandle) == parameters.count
    else {
      throw SQLBindingError(
        message: "Bindings count does not match parameters count"
      )
    }

    for (idx, argument) in parameters.enumerated(){
      if let argument: SQLBindable = argument {
        let bindingSucceeded: Bool
          = argument
          .bind(
            statementHandle,
            at: Int32(idx + 1)
          )

        guard bindingSucceeded
        else {
          throw SQLBindingError(
            message: lastErrorMessage()
          )
        }
      } else {
        let bindingResult: Int32
          = sqlite3_bind_null(
            statementHandle,
            Int32(idx + 1)
          )
        guard bindingResult == SQLITE_OK
        else {
          throw SQLBindingError(
            message: lastErrorMessage()
          )
        }
      }
    }

    return statementHandle
  }

  @inline(__always)
  private func lastErrorMessage() -> String {
    sqlite3_errmsg(handle)
      .map(String.init(cString:))
      ?? "Unknown failure reason"
  }
}

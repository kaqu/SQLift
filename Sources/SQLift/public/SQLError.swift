/// Common interface for all SQL related errors.
public protocol SQLError: Error {

  /// Database engine error message.
  var message: String { get }
}

/// Error representing database connection error.
public struct SQLConnectionError: SQLError {

  public let message: String

  public init(
    message: String
  ) {
    self.message = message
  }
}

/// Error representing invalid statement.
public struct SQLStatementError: SQLError {

  public let message: String

  public init(
    message: String
  ) {
    self.message = message
  }
}

/// Error representing invalid statement binding.
public struct SQLBindingError: SQLError {

  public let message: String

  public init(
    message: String
  ) {
    self.message = message
  }
}

/// Error representing invalid statement execution.
public struct SQLExecutionError: SQLError {

  public let message: String

  public init(
    message: String
  ) {
    self.message = message
  }
}

/// Error representing migration execution issue.
public struct SQLMigrationError: SQLError {

  public let message: String

  public init(
    message: String
  ) {
    self.message = message
  }
}

import SQLite3

/// Instance of SQL database connection.
///
/// - Note: SQLift uses SQLite as database engine, all operations has to be compatible
/// with SQLite to work correctly.
///
/// Connection instance is used to communicate with database.
/// It can execute statements and fetch data from the database.
/// Connection is automatically closed when connection instance
/// is dropped and becomes dealocated.
public final class SQLConnection {

  /// Opens new database connection.
  ///
  /// By default uses in memory SQLite if no disk path was provided.
  /// Performs all provided migrations if needed. Migrations are tracked by
  /// version number. Each element in migration array increments version counter.
  /// Migrations at indices lower than current schema version are skipped.
  /// Schema version is updated after successful execution of all migrations.
  ///
  /// - parameter path: path where SQL database file is located. In memory storage is used by default.
  /// - parameter options: SQLite openning options, by default SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE is used.
  /// - parameter migrations: List of migrations performed in provided order. Migrations count is equivalent to schema version. Empty by default.
  public static func open(
    at path: String = ":memory:",
    options: Int32 = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE,
    migrations: Array<SQLMigration> = .init()
  ) throws -> Self {
    let connection: Self
      = try .init(
      .open(
        at: path,
        options: options
      )
    )

    try connection
      .performMigrations(
        migrations
      )

    return connection
  }

  @usableFromInline
  internal let connectionHandle: SQLiteConnectionHandle

  private init(
    _ connectionHandle: SQLiteConnectionHandle
  ) {
    self.connectionHandle = connectionHandle
  }

  /// Execute provided statement.
  ///
  /// Statement is executed using this database connection.
  /// It is not returning any values and statement should not
  /// query for rows either. For retriving data from database
  /// please use ``fetch(_:with:mapping:)``.
  /// If this method finishes without throwing an error
  /// statement execution was successful.
  ///
  /// - parameter statement: statement to be executed using this connection.
  /// - parameter parameters: statement parameters used to execute it.
  @inlinable
  public func execute(
    _ statement: SQLStatement,
    with parameters: SQLBindable?...
  ) throws {
    try connectionHandle
      .execute(
        statement,
        with: parameters
      )
  }

  /// Execute provided statement expecting some result.
  ///
  /// Statement is executed using this database connection.
  /// It is expected to return some values. For executing statement
  /// without quering data please use ``execute(_:with:)``.
  /// If this method finishes without throwing an error
  /// statement execution was successful.
  ///
  /// - parameter statement: statement to be used to query data using this connection.
  /// - parameter parameters: statement parameters used to execute it.
  /// - parameter mapping: function used to map raw database rows into objects.
  @inlinable
  public func fetch<Value>(
    _ statement: SQLStatement,
    with parameters: SQLBindable?...,
    mapping: (Array<SQLRow>) throws -> Array<Value>
  ) throws -> Array<Value> {
    try mapping(
      connectionHandle
        .fetch(
          statement,
          with: parameters
        )
    )
  }

  /// Execute provided statement expecting raw rows result.
  ///
  /// Statement is executed using this database connection.
  /// It is expected to return some values. For executing statement
  /// without quering data please use ``execute(_:with:)``.
  /// If this method finishes without throwing an error
  /// statement execution was successful.
  ///
  /// - parameter statement: statement to be used to query data using this connection.
  /// - parameter parameters: statement parameters used to execute it.
  @inlinable
  public func fetch(
    _ statement: SQLStatement,
    with parameters: SQLBindable?...
  ) throws -> Array<SQLRow> {
    try connectionHandle
      .fetch(
        statement,
        with: parameters
      )
  }

  /// Begin new database transaction.
  ///
  /// Transactions cannot be nested.
  @inlinable
  public func beginTransaction() throws {
    try connectionHandle
      .execute(
        "BEGIN TRANSACTION;"
      )
  }

  /// Rollback current database transaction.
  @inlinable
  public func rollbackTransaction() throws {
    try connectionHandle
      .execute(
        "ROLLBACK TRANSACTION;"
      )
  }

  /// End current database transaction.
  @inlinable
  public func endTransaction() throws {
    try connectionHandle
      .execute(
        "END TRANSACTION;"
      )
  }

  /// Execute provided closure wrapping it with transaction
  /// with automatic rollback on fail.
  @inlinable
  public func withTransaction(
    _ transaction: (SQLConnection) throws -> Void
  ) throws {
    try beginTransaction()

    do {
      try transaction(self)
    } catch {
      try rollbackTransaction()
      throw error
    }

    try endTransaction()
  }

  private func performMigrations(
    _ migrations: Array<SQLMigration>
  ) throws {
    try execute(
        """
          CREATE TABLE IF NOT EXISTS
            _schema
          (
            handle INTEGER PRIMARY KEY,
            version INTEGER
          );
        """
      )

    let currentSchemaVersion: Int
      = try fetch(
        "SELECT version FROM _schema;"
      ) { rows -> Array<Int> in
        rows.compactMap { $0.version as Int? }
      }
      .first
      ?? 0

    guard currentSchemaVersion < migrations.count
    else {
      if currentSchemaVersion > migrations.count {
        throw SQLMigrationError(
          message: "Invalid schema version, provided: \(migrations.count), existing: \(currentSchemaVersion)"
        )
      } else {
        return // no migration needed
      }
    }

    for (idx, migration) in migrations[currentSchemaVersion...].enumerated() {
       try withTransaction { conn in
        for step in migration.steps {
          try conn
            .connectionHandle
            .execute(
              step.statement,
              with : step.parameters
            )
        }

        try conn
          .execute(
            """
             INSERT INTO
             _schema
             (handle, version)
             VALUES
             (0, ?1)
             ON CONFLICT
             (handle)
             DO UPDATE
             SET
             version=(?1);
           """,
            with: currentSchemaVersion + idx + 1
          )
       }
    }
  }
}

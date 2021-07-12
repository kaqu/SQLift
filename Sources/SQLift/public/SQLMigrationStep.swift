/// Convenience type for preparing steps of database migrations. Each step is a single
/// statement that will be executed as part of migration.
///
/// - Note: SQLift uses SQLite as database engine, all migrations has to be compatible
/// with SQLite to work correctly.
///
/// SQLMigrationStep encapsulates ``SQLStatement`` with list of ``SQLBindable`` parameters
/// used to execute statement.
/// It can be created without parameters by using static strings directly.
public struct SQLMigrationStep {

  public let statement: SQLStatement
  public var parameters: Array<SQLBindable?>

  public init(
    statement: SQLStatement,
    parameters: Array<SQLBindable?> = .init()
  ) {
    self.statement = statement
    self.parameters = parameters
  }
}

extension SQLMigrationStep: ExpressibleByStringLiteral {

  public init(
    stringLiteral value: StaticString
  ) {
    self.init(
      statement: .init(stringLiteral: value),
      parameters: .init()
    )
  }
}

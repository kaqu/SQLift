/// Convenience type for preparing database migrations.
///
/// - Note: SQLift uses SQLite as database engine, all migrations has to be compatible
/// with SQLite to work correctly.
///
/// Each migration consists of one or more ``SQLMigrationStep``
/// that represent operations that will be executed as part of migration.
/// Steps will be executed in provided order.
/// It can be created without parameters by using static strings directly
/// as a single step migration.
public struct SQLMigration {

  public let steps: Array<SQLMigrationStep>

  public init(
    steps head: SQLMigrationStep,
    _ tail: SQLMigrationStep...
  ) {
    self.steps = [head] + tail
  }
}

extension SQLMigration: ExpressibleByStringLiteral {

  public init(
    stringLiteral value: StaticString
  ) {
    self.steps = [.init(stringLiteral: value)]
  }
}
extension SQLMigration: ExpressibleByArrayLiteral {

  public init(
    arrayLiteral elements: StaticString...
  ) {
    precondition(!elements.isEmpty, "Cannot create empty migration")
    self.steps = elements.map { .init(stringLiteral: $0) }
  }
}


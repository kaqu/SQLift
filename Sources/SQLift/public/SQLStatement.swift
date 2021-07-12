/// SQL database statement.
/// Can be use to execute commands or fetch data from ``SQLConnection``.
///
/// - Note: SQLift uses SQLite as database engine, all statements has to be compatible
/// with SQLite to work correctly.
///
/// In order to prevent SQL injections risk ``SQLStatement``
/// instances can be created only by using static strings
/// and cannot be modified or concatenated.
/// However you can i.e. extend it to use static properties defining
/// commonly used statements.
public struct SQLStatement {

  internal let rawString: String
}

extension SQLStatement: ExpressibleByStringLiteral {

  public init(
    stringLiteral value: StaticString
  ) {
    self.init(rawString: value.description)
  }
}

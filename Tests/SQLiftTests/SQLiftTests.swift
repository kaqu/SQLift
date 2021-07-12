import XCTest

import SQLift

final class SQLiftTests: XCTestCase {

  func test_example() {
    let migrations: Array<SQLMigration> = [
      SQLMigration(
        steps:
          "CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, label TEXT, age INTEGER)",
          "CREATE TABLE passwords (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, secret TEXT)",
          "CREATE TABLE user_passwords (user_id INTEGER NOT NULL, password_id INTEGER NOT NULL, FOREIGN KEY(user_id) REFERENCES users(id), FOREIGN KEY(password_id) REFERENCES passwords(id))"
      )
    ]
    do {
      let connection: SQLConnection
        = try .open(
          migrations: migrations
        )

      try connection.withTransaction { conn in
        try conn.execute("INSERT INTO users (name, label, age) VALUES (?, ?, ?)", with: "Adam", nil, 24)
        try conn.execute("INSERT INTO users (name, label, age) VALUES (?, ?, ?)", with: "Ewa", "EV", 22)
        try conn.execute("INSERT INTO users (name, label, age) VALUES (?, ?, ?)", with: "Rafał", "raf", 17)
        try conn.execute("INSERT INTO passwords (secret) VALUES (?)", with: "pass")
        try conn.execute("INSERT INTO passwords (secret) VALUES (?)", with: "dassfg")
        try conn.execute("INSERT INTO passwords (secret) VALUES (?)", with: "fdsafsd")
        try conn.execute("INSERT INTO user_passwords (user_id, password_id) VALUES (?, ?)", with: 1, 1)
        try conn.execute("INSERT INTO user_passwords (user_id, password_id) VALUES (?, ?)", with: 1, 2)
      }

      print(try connection.fetch("SELECT * FROM users;"))

      let query: SQLStatement
        = """
          SELECT
            users.id AS user_id,
            users.name,
            users.label,
            users.age,
            passwords.secret AS secret
          FROM
            users
          JOIN
            user_passwords
          ON
            users.id = user_passwords.user_id
          JOIN
            passwords
          ON
            user_passwords.password_id = passwords.id
          WHERE
            name
          LIKE
            ?
          ;
          """

      print(
        try connection.fetch(
          query,
          with: "Adam"
          )
        )

      print(
        try connection.fetch(
          query,
          with: "Adam",
          mapping: { rows -> Array<User> in
            var userIDs: Set<Int> = .init()
            return rows
              .compactMap { row -> User? in
                guard let userID: Int = row.user_id
                else { return nil }
                guard !userIDs.contains(userID)
                else { return nil }
                userIDs.insert(userID)
                let passwords: Array<Password>
                  = rows.compactMap { row in
                    guard row.user_id == userID
                    else { return nil }
                    return Password.from(row: row)
                  }
                return User.from(row: row, passwords: passwords)
              }
          }
        )
      )

      print(
        try connection.fetch(
          "SELECT version FROM _schema"
        )
      )
    } catch {
      XCTFail("\(error)")
    }
  }
}


struct User {

  var name: String
  var label: String?
  var age: Int
  var passwords: Array<Password>

  static func from(row: SQLRow, passwords: Array<Password>) -> Self? {
    guard
      let name: String = row.name,
      let label: String? = row.label as String??,
      let age: Int = row.age
    else { return nil }
    return Self(name: name, label: label, age: age, passwords: passwords)
  }
}

struct Password {

  var secret: String

  static func from(row: SQLRow) -> Self? {
    guard let secret: String = row.secret
    else { return nil }
    return Self(secret: secret)
  }
}

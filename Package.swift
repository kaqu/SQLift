// swift-tools-version:5.4

import PackageDescription

let package = Package(
  name: "SQLift",
  platforms: [
    .iOS(.v14),
    .macOS(.v11)
  ],
  products: [
    .library(
      name: "SQLift",
      targets: [
        "SQLift"
      ]
    ),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "SQLift",
      dependencies: []
    ),
    .testTarget(
      name: "SQLiftTests",
      dependencies: [
        "SQLift"
      ]
    ),
  ]
)

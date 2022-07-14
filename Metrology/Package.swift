// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "Metrology",
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "Metrology",
      targets: ["Metrology"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "Metrology",
      dependencies: []),
    .testTarget(
      name: "MetrologyTests",
      dependencies: ["Metrology"]),
  ]
)

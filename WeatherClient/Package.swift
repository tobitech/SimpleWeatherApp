// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "WeatherClient",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(
      name: "WeatherClient",
      targets: ["WeatherClient"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "WeatherClient",
      dependencies: []),
    .testTarget(
      name: "WeatherClientTests",
      dependencies: ["WeatherClient"]),
  ]
)

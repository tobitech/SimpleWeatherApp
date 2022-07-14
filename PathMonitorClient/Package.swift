// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "PathMonitorClient",
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "PathMonitorClient",
      targets: ["PathMonitorClient"]),
    .library(
      name: "PathMonitorClientLive",
      targets: ["PathMonitorClientLive"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "PathMonitorClient",
      dependencies: []),
    .testTarget(
      name: "PathMonitorClientTests",
      dependencies: ["PathMonitorClient"]),
    
      .target(
        name: "PathMonitorClientLive",
        dependencies: []),
  ]
)

// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "SystemUp",
  platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  products: [
    .library(name: "SystemUp", targets: ["SystemUp"]),
    .library(name: "SystemFileManager", targets: ["SystemFileManager"]),
    .library(name: "Command", targets: ["Command"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-system.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/SyscallValue.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/CUtility.git", from: "0.8.0"),
  ],
  targets: [
    .target(
      name: "CSystemUp"),
    .target(
      name: "SystemLibc",
      dependencies: [
        "CSystemUp",
      ]),
    .target(
      name: "SystemUp",
      dependencies: [
        "SystemLibc",
        .product(name: "SyscallValue", package: "SyscallValue"),
        .product(name: "CUtility", package: "CUtility"),
        .product(name: "SystemPackage", package: "swift-system"),
      ],
      swiftSettings: [
        .unsafeFlags(["-Xfrontend", "-disable-stack-protector"]),
        .unsafeFlags(["-Xfrontend", "-disable-reflection-metadata"]),
        .enableExperimentalFeature("Extern"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
      ]
    ),
    .target(
      name: "SystemFileManager",
      dependencies: [
        "SystemUp",
      ]),
    .target(
      name: "Command",
      dependencies: [
        "SystemUp",
      ]),
    .testTarget(
      name: "SystemExtensionTests",
      dependencies: ["SystemUp"]),
  ]
)

package.targets.append(contentsOf: [
])

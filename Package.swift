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
    .package(url: "https://github.com/kojirou1994/CUtility.git", branch: "main"),
    .package(url: "https://github.com/kojirou1994/LittleC.git", branch: "main"),
  ],
  targets: [
    .target(
      name: "SystemLibc",
      dependencies: [
        .product(name: "LittleC", package: "LittleC"),
      ]),
    .target(
      name: "SystemUp",
      dependencies: [
        "SystemLibc",
        .product(name: "SyscallValue", package: "CUtility"),
        .product(name: "CUtility", package: "CUtility"),
      ],
      swiftSettings: [
        .define("APPLE", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .macCatalyst])),
        .define("UNIX_BSD", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .macCatalyst])),
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
      ],
      swiftSettings: [
        .define("APPLE", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .macCatalyst])),
        .define("UNIX_BSD", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .macCatalyst])),
        .unsafeFlags(["-Xfrontend", "-disable-stack-protector"]),
      ]
    ),
    .target(
      name: "Command",
      dependencies: [
        "SystemUp",
      ]),
    .testTarget(
      name: "SystemExtensionTests",
      dependencies: ["SystemUp", "SystemFileManager"]),
  ]
)

package.targets.append(contentsOf: [
])

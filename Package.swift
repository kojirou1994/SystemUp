// swift-tools-version: 5.9

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
    .package(url: "https://github.com/kojirou1994/SyscallValue.git", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/CUtility.git", from: "0.3.3"),
  ],
  targets: [
    .target(
      name: "CSystemUp"),
    .target(
      name: "CProc"),
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
        .product(name: "CGeneric", package: "CUtility"),
        .product(name: "SystemPackage", package: "swift-system"),
      ]),
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

#if os(macOS)
package.products.append(.library(name: "Proc", targets: ["Proc"]))
package.targets.append(contentsOf: [
  .target(
    name: "Proc",
    dependencies: [
      "CProc",
      .product(name: "SyscallValue", package: "SyscallValue"),
      .product(name: "CUtility", package: "CUtility"),
      .product(name: "SystemPackage", package: "swift-system"),
    ]),
  .testTarget(
    name: "ProcTests",
    dependencies: ["Proc"]),
])
#endif

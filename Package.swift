// swift-tools-version:5.4

import PackageDescription

let package = Package(
  name: "SystemUp",
  products: [
    .library(name: "SystemUp", targets: ["SystemUp"]),
    .library(name: "SystemFileManager", targets: ["SystemFileManager"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-system.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/SyscallValue.git", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/CUtility.git", from: "0.0.1"),
  ],
  targets: [
    .target(
      name: "CSystemUp"),
    .target(
      name: "CProc"),
    .target(
      name: "SystemUp",
      dependencies: [
        "CSystemUp",
        .product(name: "SyscallValue", package: "SyscallValue"),
        .product(name: "CUtility", package: "CUtility"),
        .product(name: "SystemPackage", package: "swift-system"),
      ]),
    .target(
      name: "SystemFileManager",
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

// swift-tools-version:5.4

import PackageDescription

let package = Package(
  name: "SystemExtension",
  products: [
    .library(name: "SystemExtension", targets: ["SystemExtension"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-system.git", from: "1.0.0"),
    .package(url: "https://github.com/kojirou1994/SyscallValue.git", from: "0.0.1"),
    .package(url: "https://github.com/kojirou1994/Kwift.git", from: "0.8.9"),
  ],
  targets: [
    .target(
      name: "SystemExtension",
      dependencies: [
        .product(name: "SyscallValue", package: "SyscallValue"),
        .product(name: "KwiftC", package: "Kwift"),
        .product(name: "SystemPackage", package: "swift-system"),
      ]),
    .testTarget(
      name: "SystemExtensionTests",
      dependencies: ["SystemExtension"]),
  ]
)

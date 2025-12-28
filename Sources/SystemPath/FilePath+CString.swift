import CStringInterop

#if APPLE
import System
@_exported import CUtilityDarwin
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public typealias FilePath = System.FilePath
#else
import SystemPackage
public typealias FilePath = SystemPackage.FilePath
#endif

#if !APPLE
import SystemPackage
import SwiftFix

extension FilePath: @retroactive CStringConvertible {
  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  public func withUnsafeCString<R, E>(_ body: (UnsafePointer<CChar>) throws(E) -> R) throws(E) -> R where E : Error, R : ~Copyable {
    var v: R!
    try toTypedThrows(E.self) {
      try withCString { cString in
        v = try body(cString)
      }
    }
    return v
  }
}

extension FilePath: @retroactive ContiguousUTF8Bytes {
  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  public func withContiguousUTF8Bytes<R, E>(_ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error, R : ~Copyable {
    var v: R!
    try toTypedThrows(E.self) {
      try withCString { cString in
        v = try body(.init(start: cString, count: self.length))
      }
    }
    return v
  }
}

extension FilePath.Component: @retroactive CStringConvertible {
  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  public func withUnsafeCString<R, E>(_ body: (UnsafePointer<CChar>) throws(E) -> R) throws(E) -> R where E : Error, R : ~Copyable {
    var v: R!
    try toTypedThrows(E.self) {
      try withPlatformString { cString in
        v = try body(cString)
      }
    }
    return v
  }
}
#endif

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public extension FilePath {
  @available(macOS 12.0, *)
  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  init(_ cString: borrowing some CString) {
    self = cString.withUnsafeCString(Self.init(platformString:))
  }
}

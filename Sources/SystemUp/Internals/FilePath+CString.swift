import CUtility
import SystemPackage

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


extension FilePath {
  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  public init(_ cString: borrowing DynamicCString) {
    self = cString.withUnsafeCString { cString in
      FilePath(platformString: cString)
    }
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

import CStringInterop

/// DynamicCString with cached length
public struct DynamicCStringWithLength: ~Copyable, @unchecked Sendable {

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  public init(cString: consuming DynamicCString, forceLength: Int? = nil, fixTerminationNull: Bool = false) {
    if let forceLength {
      if fixTerminationNull {
        cString.cString[forceLength] = 0
      }
      self._length = forceLength
    } else {
      self._length = cString.length
    }
    self.cString = cString
  }

  @_alwaysEmitIntoClient
  public var cString: DynamicCString {
    didSet {
      // update length
      _length = cString.length
    }
  }

  /// cached length, auto-updated when cString changed
  @usableFromInline
  internal var _length: Int

  @_alwaysEmitIntoClient
  public var length: Int {
    _length
  }
}

extension DynamicCStringWithLength {

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  public mutating func withMutableCString<Result: ~Copyable, E: Error>(_ body: (UnsafeMutablePointer<CChar>) throws(E) -> Result) throws(E) -> Result {
    try cString.withMutableCString(body)
  }

}

extension DynamicCStringWithLength: ContiguousUTF8Bytes {
  public func withContiguousUTF8Bytes<R, E>(_ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E : Error, R : ~Copyable {
    try body(.init(start: cString.cString, count: length))
  }
}


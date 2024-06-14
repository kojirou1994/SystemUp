public enum Memory {}

public extension Memory {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func zeroed<T>() -> T {
    withUnsafeTemporaryAllocation(of: T.self, capacity: 1) { buf in
      UnsafeMutableRawBufferPointer(buf).initializeMemory(as: UInt8.self, repeating: 0)
      return buf[0]
    }
  }
}

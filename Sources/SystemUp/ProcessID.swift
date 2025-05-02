import SystemLibc

public struct ProcessID: RawRepresentable, Sendable, Hashable, BitwiseCopyable {
  public let rawValue: Int32

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }
}

public extension ProcessID {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var current: Self { .init(rawValue: SystemLibc.getpid()) }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var parent: Self { .init(rawValue: SystemLibc.getppid()) }
}

extension ProcessID: CustomStringConvertible, Comparable {
  public var description: String { rawValue.description }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func < (lhs: ProcessID, rhs: ProcessID) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

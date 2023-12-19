import SystemLibc

public struct ProcessID: RawRepresentable {
  public let rawValue: Int32

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }
}

public extension ProcessID {
  @_alwaysEmitIntoClient
  static var current: Self { .init(rawValue: SystemLibc.getpid()) }

  @_alwaysEmitIntoClient
  static var parent: Self { .init(rawValue: SystemLibc.getppid()) }
}

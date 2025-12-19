import SystemLibc

public extension SystemCall {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exit(_ code: CInt) -> Never {
    SystemLibc.exit(code)
  }
}

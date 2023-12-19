import SystemLibc

public struct SignalHandler {
  @usableFromInline
  internal init(_ body: (@convention(c) (Int32) -> Void)?) {
    self.body = body
  }

  public let body: (@convention(c) (Int32) -> Void)?
}

public extension SignalHandler {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var ignore: Self { .init(SystemLibc.SIG_IGN) }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var `default`: Self { .init(SystemLibc.SIG_DFL) }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func custom(_ body: @convention(c) (_ signal: Int32) -> Void) -> Self {
    .init(body)
  }
}

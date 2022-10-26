import SystemLibc

public struct SignalSet: RawRepresentable {
  public var rawValue: sigset_t

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  public init(rawValue: sigset_t) {
    self.rawValue = rawValue
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  public init() {
    self.rawValue = .init()
  }
}

public extension SignalSet {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  mutating func add(signal: Int32) {
    sigaddset(&rawValue, signal)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  mutating func delete(signal: Int32) {
    sigdelset(&rawValue, signal)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  mutating func removeAll() {
    sigemptyset(&rawValue)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  mutating func fillAll() {
    sigfillset(&rawValue)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  func contains(signal: Int32) -> Bool {
    withUnsafePointer(to: rawValue) { sigset in
      sigismember(sigset, signal) == 1
    }
  }
}

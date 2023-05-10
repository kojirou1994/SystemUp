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
    removeAll()
  }
}

public extension SignalSet {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  mutating func add(signal: Signal) {
    sigaddset(&rawValue, signal.rawValue)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  mutating func delete(signal: Signal) {
    sigdelset(&rawValue, signal.rawValue)
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
  func contains(signal: Signal) -> Bool {
    withUnsafePointer(to: rawValue) { sigset in
      sigismember(sigset, signal.rawValue) == 1
    }
  }
}

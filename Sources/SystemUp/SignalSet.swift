import SystemLibc

public struct SignalSet: RawRepresentable, BitwiseCopyable, Sendable {

  public var rawValue: sigset_t

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  public init(rawValue: sigset_t) {
    self.rawValue = rawValue
  }

}

// MARK: Base APIs
public extension SignalSet {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func insert(_ signal: Signal) {
    sigaddset(&self.rawValue, signal.rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func remove(_ signal: Signal) {
    sigdelset(&self.rawValue, signal.rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func removeAll() {
    sigemptyset(&self.rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func fillAll() {
    sigfillset(&self.rawValue)
  }

  // NOTE: mutating marked for performance
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func contains(_ signal: Signal) -> Bool {
    withUnsafeMutablePointer(to: &self.rawValue) { sigset in
      sigismember(sigset, signal.rawValue) == 1
    }
  }
}

// MARK: Syscall APIs
public extension SignalSet {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func wait(clearedSignalOutput signal: UnsafeMutablePointer<Signal>) {
    assertNoFailure { // only fail if set specifies one or more invalid signal numbers.
      SyscallUtilities.voidOrErrno {
        withUnsafePointer(to: self.rawValue) { sigset in
          sigwait(sigset, .init(OpaquePointer(signal)))
        }
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func getPendingSignals() {
    assertNoFailure { // The sigpending function does not currently detect any errors.
      SyscallUtilities.voidOrErrno {
        sigpending(&self.rawValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func suspend() throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      withUnsafePointer(to: self.rawValue) { sigset in
        sigsuspend(sigset)
      }
    }.get()
  }

}


// MARK: Helper
public extension SignalSet {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var all: Self {
    var v: Self = Memory.undefined()
    v.fillAll()
    return v
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var empty: Self {
    var v: Self = Memory.undefined()
    v.removeAll()
    return v
  }
}

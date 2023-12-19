import SystemLibc
import CUtility
import SystemPackage

public typealias SignalSet = sigset_t

// MARK: Base APIs
public extension SignalSet {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func insert(_ signal: Signal) {
    sigaddset(&self, signal.rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func remove(_ signal: Signal) {
    sigdelset(&self, signal.rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func removeAll() {
    sigemptyset(&self)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func fillAll() {
    sigfillset(&self)
  }

  // NOTE: mutating marked for performance
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func contains(_ signal: Signal) -> Bool {
    withUnsafeMutablePointer(to: &self) { sigset in
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
        withUnsafePointer(to: self) { sigset in
          sigwait(sigset, .init(OpaquePointer(signal)))
        }
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func getPendingSignals() {
    assertNoFailure { // The sigpending function does not currently detect any errors.
      SyscallUtilities.voidOrErrno {
        sigpending(&self)
      }
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func suspend() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      withUnsafePointer(to: self) { sigset in
        sigsuspend(sigset)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var currentMask: Self {
    var v = Self.init()
    v.getCurrentMask()
    return v
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func getCurrentMask() {
    assertNoFailure {
      SyscallUtilities.voidOrErrno {
        sigprocmask(0, nil, &self)
      }
    }
  }

  struct ManipulateMethod: MacroRawRepresentable {
    public let rawValue: Int32
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var add: Self { .init(macroValue: SIG_BLOCK) }

    @_alwaysEmitIntoClient
    public static var remove: Self { .init(macroValue: SIG_UNBLOCK) }

    @_alwaysEmitIntoClient
    public static var replace: Self { .init(macroValue: SIG_SETMASK) }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func manipulateCurrentSignalMask(_ method: ManipulateMethod, oldOutput: UnsafeMutablePointer<Self>?) {
    assertNoFailure {
      SyscallUtilities.voidOrErrno {
        withUnsafePointer(to: self) { sigset in
          sigprocmask(method.rawValue, sigset, oldOutput)
        }
      }
    }
  }

}

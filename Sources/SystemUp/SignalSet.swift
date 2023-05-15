import SystemLibc
import CUtility
import SystemPackage

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

// MARK: Base APIs
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

// MARK: Syscall APIs
public extension SignalSet {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  func wait(clearedSignalOutput signal: UnsafeMutablePointer<Signal>) {
    assertNoFailure { // only fail if set specifies one or more invalid signal numbers.
      SyscallUtilities.voidOrErrno {
        withUnsafePointer(to: rawValue) { sigset in
          sigwait(sigset, .init(OpaquePointer(signal)))
        }
      }
    }
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  mutating func getPendingSignals() {
    assertNoFailure { // The sigpending function does not currently detect any errors.
      SyscallUtilities.voidOrErrno {
        sigpending(&rawValue)
      }
    }
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @discardableResult
  mutating func suspend() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      withUnsafePointer(to: rawValue) { sigset in
        sigsuspend(sigset)
      }
    }
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static var currentMask: Self {
    var v = Self.init()
    v.getCurrentMask()
    return v
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  mutating func getCurrentMask() {
    assertNoFailure {
      SyscallUtilities.voidOrErrno {
        sigprocmask(0, nil, &rawValue)
      }
    }
  }

  struct ManipulateMethod: MacroRawRepresentable {
    public let rawValue: Int32
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

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  func manipulateCurrentSignalMask(_ method: ManipulateMethod, oldOutput: UnsafeMutablePointer<Self>?) {
    assertNoFailure {
      SyscallUtilities.voidOrErrno {
        withUnsafePointer(to: rawValue) { sigset in
          sigprocmask(method.rawValue, sigset, oldOutput?.pointer(to: \.rawValue))
        }
      }
    }
  }

}

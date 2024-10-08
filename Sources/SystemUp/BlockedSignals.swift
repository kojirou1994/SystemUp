import SystemLibc
import SystemPackage
import CUtility

public enum BlockedSignals {
  case singleThreaded
  case multiThreaded

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public var current: SignalSet {
    var v: SignalSet = Memory.undefined()
    copyCurrent(to: &v)
    return v
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func copyCurrent(to dest: inout SignalSet) {
    assertNoFailure {
      switch self {
      case .singleThreaded:
        SyscallUtilities.voidOrErrno {
          sigprocmask(0, nil, &dest.rawValue)
        }
      case .multiThreaded:
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_sigmask(0, nil, &dest.rawValue)
        }
      }
    }
  }

  public struct ManipulateMethod: MacroRawRepresentable {
    public let rawValue: Int32
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var insert: Self { .init(macroValue: SIG_BLOCK) }

    @_alwaysEmitIntoClient
    public static var remove: Self { .init(macroValue: SIG_UNBLOCK) }

    @_alwaysEmitIntoClient
    public static var replace: Self { .init(macroValue: SIG_SETMASK) }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func manipulate(method: ManipulateMethod, value: SignalSet, oldOutput: UnsafeMutablePointer<SignalSet>? = nil) {
    assertNoFailure {
      withUnsafePointer(to: value.rawValue) { sigset in
        switch self {
        case .singleThreaded:
          SyscallUtilities.voidOrErrno {
            sigprocmask(method.rawValue, sigset, oldOutput?.pointer(to: \.rawValue))
          }
        case .multiThreaded:
          SyscallUtilities.errnoOrZeroOnReturn {
            pthread_sigmask(method.rawValue, sigset, oldOutput?.pointer(to: \.rawValue))
          }
        }
      }
    }
  }
}

import SystemLibc
import CUtility

public struct ResourceUsage: Sendable {
  @usableFromInline
  internal var rawValue: rusage

  public struct Who: MacroRawRepresentable {
    public let rawValue: Int32
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }
}

#if APPLE
extension ResourceUsage: BitwiseCopyable {}
#endif

public extension ResourceUsage {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func get(for who: Who) {
    assertNoFailure {
      SyscallUtilities.voidOrErrno {
        getrusage(who.rawValue, &rawValue)
      }
    }
  }

}

public extension ResourceUsage.Who {
  @_alwaysEmitIntoClient
  static var currentProcess: Self { .init(macroValue: RUSAGE_SELF) }
  @_alwaysEmitIntoClient
  static var currentProcessChildren: Self { .init(macroValue: RUSAGE_CHILDREN) }
}

public extension ResourceUsage {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var userTime: Timeval {
    .init(rawValue: rawValue.ru_utime)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var systemTime: Timeval {
    .init(rawValue: rawValue.ru_stime)
  }

  /// the maximum resident set size utilized (in bytes).
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var maxResidentSetSize: Int {
    #if APPLE
    let ratio = 1
    #else
    let ratio = 1024
    #endif
    return rawValue.ru_maxrss * ratio
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var integralSharedMemorySize: Int {
    rawValue.ru_ixrss
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var integralUnsharedDataSize: Int {
    rawValue.ru_idrss
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var integralUnsharedStackSize: Int {
    rawValue.ru_isrss
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var pageReclaims: Int {
    rawValue.ru_minflt
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var pageFaults: Int {
    rawValue.ru_majflt
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var swaps: Int {
    rawValue.ru_nswap
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var blockInputOperations: Int {
    rawValue.ru_inblock
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var blockOutputOperations: Int {
    rawValue.ru_oublock
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var ipcMessagesSent: Int {
    rawValue.ru_msgsnd
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var ipcMessagesReceived: Int {
    rawValue.ru_msgrcv
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var signalsReceived: Int {
    rawValue.ru_nsignals
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var voluntaryContextSwitches: Int {
    rawValue.ru_nvcsw
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var involuntaryContextSwitches: Int {
    rawValue.ru_nivcsw
  }
}

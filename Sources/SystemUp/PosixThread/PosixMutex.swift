import SystemLibc
import CUtility
import SwiftExperimental

@_staticExclusiveOnly
public struct PosixMutex: ~Copyable, @unchecked Sendable {

  @usableFromInline
  internal let value: StableAddress<pthread_mutex_t> = .undefined

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(attributes: borrowing Attributes) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_init(value._address, attributes.value._address)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_init(value._address, nil)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    PosixThread.call {
      pthread_mutex_destroy(value._address)
    }
  }

}

public extension PosixMutex {

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func lock() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_lock(value._address)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func unlock() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_unlock(value._address)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func tryLock() -> Bool {
    pthread_mutex_trylock(value._address) == 0
  }
}

extension PosixMutex {
  @_staticExclusiveOnly
  public struct Attributes: ~Copyable {

    @usableFromInline
    internal var value: StableAddress<pthread_mutexattr_t> = .undefined

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() throws(Errno) {
      try SyscallUtilities.errnoOrZeroOnReturn {
        pthread_mutexattr_init(value._address)
      }.get()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    deinit {
      PosixThread.call {
        pthread_mutexattr_destroy(value._address)
      }
    }

    public struct MutexType: MacroRawRepresentable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      public let rawValue: Int32

      @_alwaysEmitIntoClient
      public static var normal: Self { .init(macroValue: PTHREAD_MUTEX_NORMAL) }
      @_alwaysEmitIntoClient
      public static var errorCheck: Self { .init(macroValue: PTHREAD_MUTEX_ERRORCHECK) }
      @_alwaysEmitIntoClient
      public static var recursive: Self { .init(macroValue: PTHREAD_MUTEX_RECURSIVE) }
      @_alwaysEmitIntoClient
      public static var `default`: Self { .init(macroValue: PTHREAD_MUTEX_DEFAULT) }
    }

    public struct Policy: MacroRawRepresentable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      public let rawValue: Int32

      #if APPLE
      @_alwaysEmitIntoClient
      public static var firstFit: Self { .init(macroValue: PTHREAD_MUTEX_POLICY_FIRSTFIT_NP) }
      @_alwaysEmitIntoClient
      public static var fairShare: Self { .init(macroValue: PTHREAD_MUTEX_POLICY_FAIRSHARE_NP) }
      #endif
    }

    public struct MutexProtocol: MacroRawRepresentable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      public let rawValue: Int32

      @_alwaysEmitIntoClient
      public static var none: Self { .init(macroValue: PTHREAD_PRIO_NONE) }
      @_alwaysEmitIntoClient
      public static var inherit: Self { .init(macroValue: PTHREAD_PRIO_INHERIT) }
      @_alwaysEmitIntoClient
      public static var protect: Self { .init(macroValue: PTHREAD_PRIO_PROTECT) }
    }
  }

  public struct ProcessShared: MacroRawRepresentable {
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    @_alwaysEmitIntoClient
    public static var shared: Self { .init(macroValue: PTHREAD_PROCESS_SHARED) }
    @_alwaysEmitIntoClient
    public static var `private`: Self { .init(macroValue: PTHREAD_PROCESS_PRIVATE) }
  }
}

public extension PosixMutex {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var prioceiling: Int32 {
    get {
      PosixThread.get {
        pthread_mutex_getprioceiling(value._address, $0)
      }
    }
    nonmutating set {
      var value: Int32 = 0
      PosixThread.call {
        pthread_mutex_setprioceiling(self.value._address, newValue, &value)
      }
    }
  }
}

public extension PosixMutex.Attributes {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var prioceiling: Int32 {
    get {
      PosixThread.get {
        pthread_mutexattr_getprioceiling(value._address, $0)
      }
    }
    nonmutating set {
      PosixThread.call {
        pthread_mutexattr_setprioceiling(value._address, newValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var `protocol`: Int32 {
    get {
      PosixThread.get {
        pthread_mutexattr_getprotocol(value._address, $0)
      }
    }
    nonmutating set {
      PosixThread.call {
        pthread_mutexattr_setprotocol(value._address, newValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    get {
      PosixThread.get {
        pthread_mutexattr_getpshared(value._address, $0)
      }
    }
    nonmutating set {
      PosixThread.call {
        pthread_mutexattr_setpshared(value._address, newValue.rawValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var type: MutexType {
    get {
      PosixThread.get {
        pthread_mutexattr_gettype(value._address, $0)
      }
    }
    nonmutating set {
      PosixThread.call {
        pthread_mutexattr_settype(value._address, newValue.rawValue)
      }
    }
  }

  #if APPLE
  @available(macOS 10.13.4, iOS 11.3, watchOS 4.3, tvOS 11.3, *)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var policy: Policy {
    get {
      PosixThread.get {
        pthread_mutexattr_getpolicy_np(value._address, $0)
      }
    }
    nonmutating set {
      PosixThread.call {
        pthread_mutexattr_setpolicy_np(value._address, newValue.rawValue)
      }
    }
  }
  #endif
}

import SystemLibc
import SystemPackage
import CUtility

public struct PosixMutex: ~Copyable, @unchecked Sendable {

  @usableFromInline
  internal let rawAddress: UnsafeMutablePointer<pthread_mutex_t> = .allocate(capacity: 1)

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(attributes: borrowing Attributes) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_init(rawAddress, attributes.rawAddress)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_init(rawAddress, nil)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    PosixThread.call {
      pthread_mutex_destroy(rawAddress)
    }
    rawAddress.deallocate()
  }

}

public extension PosixMutex {

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func lock() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_lock(rawAddress)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func unlock() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_unlock(rawAddress)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func tryLock() -> Bool {
    pthread_mutex_trylock(rawAddress) == 0
  }
}

extension PosixMutex {
  public struct Attributes: ~Copyable, @unchecked Sendable {

    @usableFromInline
    internal var rawAddress: UnsafeMutablePointer<pthread_mutexattr_t> = .allocate(capacity: 1)

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() throws(Errno) {
      try initialize()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    deinit {
      destroy()
      rawAddress.deallocate()
    }

    /// destroy and initialize
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public func reset() throws(Errno) {
      destroy()
      try initialize()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    internal func initialize() throws(Errno) {
      try SyscallUtilities.errnoOrZeroOnReturn {
        pthread_mutexattr_init(rawAddress)
      }.get()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    internal func destroy() {
      PosixThread.call {
        pthread_mutexattr_destroy(rawAddress)
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

      #if canImport(Darwin)
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
        pthread_mutex_getprioceiling(rawAddress, $0)
      }
    }
    set {
      var value: Int32 = 0
      PosixThread.call {
        pthread_mutex_setprioceiling(rawAddress, newValue, &value)
      }
    }
  }
}

public extension PosixMutex.Attributes {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var prioceiling: Int32 {
    get {
      PosixThread.get {
        pthread_mutexattr_getprioceiling(rawAddress, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setprioceiling(rawAddress, newValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var `protocol`: Int32 {
    get {
      PosixThread.get {
        pthread_mutexattr_getprotocol(rawAddress, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setprotocol(rawAddress, newValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    get {
      PosixThread.get {
        pthread_mutexattr_getpshared(rawAddress, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setpshared(rawAddress, newValue.rawValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var type: MutexType {
    get {
      PosixThread.get {
        pthread_mutexattr_gettype(rawAddress, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_settype(rawAddress, newValue.rawValue)
      }
    }
  }

  #if canImport(Darwin)
  @available(macOS 10.13.4, iOS 11.3, watchOS 4.3, tvOS 11.3, *)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var policy: Policy {
    get {
      PosixThread.get {
        pthread_mutexattr_getpolicy_np(rawAddress, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setpolicy_np(rawAddress, newValue.rawValue)
      }
    }
  }
  #endif
}

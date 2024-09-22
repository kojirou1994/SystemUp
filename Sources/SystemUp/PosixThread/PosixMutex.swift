import SystemLibc
import SystemPackage
import CUtility

public struct PosixMutex: ~Copyable {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(attributes: borrowing Attributes) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      withUnsafePointer(to: attributes.rawValue) { pthread_mutex_init(&rawValue, $0) }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_init(&rawValue, nil)
    }.get()
  }

  @usableFromInline
  internal var rawValue: pthread_mutex_t = .init()
}

public extension PosixMutex {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func destroy() {
    PosixThread.call {
      pthread_mutex_destroy(&rawValue)
    }
  }

  @available(*, noasync)
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func lock() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_lock(&rawValue)
    }
  }

  @available(*, noasync)
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func unlock() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_unlock(&rawValue)
    }
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func tryLock() -> Bool {
    pthread_mutex_trylock(&rawValue) == 0
  }
}

extension PosixMutex {
  public struct Attributes: ~Copyable {

    @usableFromInline
    internal var rawValue: pthread_mutexattr_t = .init()

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(type: MutexType? = nil) throws(Errno) {
      try SyscallUtilities.errnoOrZeroOnReturn {
        pthread_mutexattr_init(&rawValue)
      }.get()
      if let type = type {
        self.type = type
      }
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public consuming func destroy() {
      PosixThread.call {
        pthread_mutexattr_destroy(&rawValue)
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
      withUnsafePointer(to: rawValue) { mutex in
        PosixThread.get {
          pthread_mutex_getprioceiling(mutex, $0)
        }
      }
    }
    set {
      var value: Int32 = 0
      PosixThread.call {
        pthread_mutex_setprioceiling(&rawValue, newValue, &value)
      }
    }
  }
}

public extension PosixMutex.Attributes {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var prioceiling: Int32 {
    get {
      withUnsafePointer(to: rawValue) { mutex in
        PosixThread.get {
          pthread_mutexattr_getprioceiling(mutex, $0)
        }
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setprioceiling(&rawValue, newValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var `protocol`: Int32 {
    get {
      withUnsafePointer(to: rawValue) { mutex in
        PosixThread.get {
          pthread_mutexattr_getprotocol(mutex, $0)
        }
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setprotocol(&rawValue, newValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    get {
      withUnsafePointer(to: rawValue) { mutex in
        PosixThread.get {
          pthread_mutexattr_getpshared(mutex, $0)
        }
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setpshared(&rawValue, newValue.rawValue)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var type: MutexType {
    get {
      withUnsafePointer(to: rawValue) { mutex in
        PosixThread.get {
          pthread_mutexattr_gettype(mutex, $0)
        }
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_settype(&rawValue, newValue.rawValue)
      }
    }
  }

  #if canImport(Darwin)
  @available(macOS 10.13.4, iOS 11.3, watchOS 4.3, tvOS 11.3, *)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var policy: Policy {
    get {
      withUnsafePointer(to: rawValue) { mutex in
        PosixThread.get {
          pthread_mutexattr_getpolicy_np(mutex, $0)
        }
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setpolicy_np(&rawValue, newValue.rawValue)
      }
    }
  }
  #endif
}

import SystemLibc
import SystemPackage
import CUtility

public struct PosixMutex {
  @inlinable
  internal init() {}

  @usableFromInline
  internal var rawValue: pthread_mutex_t = .init()
}

public extension PosixMutex {

  @inlinable
  static func create(attributes: Attributes? = nil) -> Result<Self, Errno> {
    var mutex = Self.init()
    return SyscallUtilities.errnoOrZeroOnReturn {
      if let attributes = attributes {
        return withCastedUnsafePointer(to: attributes) { pthread_mutex_init(&mutex.rawValue, $0) }
      } else {
        return pthread_mutex_init(&mutex.rawValue, nil)
      }
    }.map { mutex }
  }

  @inlinable
  mutating func destroy() {
    PosixThread.call {
      pthread_mutex_destroy(&rawValue)
    }
  }

  @available(*, noasync)
  @inlinable
  @discardableResult
  mutating func lock() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_lock(&rawValue)
    }
  }

  @available(*, noasync)
  @inlinable
  @discardableResult
  mutating func unlock() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_mutex_unlock(&rawValue)
    }
  }

  @available(*, noasync)
  @inlinable
  mutating func tryLock() -> Bool {
    pthread_mutex_trylock(&rawValue) == 0
  }
}

extension PosixMutex {
  public struct Attributes {
    @usableFromInline
    internal init() {}

    @usableFromInline
    internal var rawValue: pthread_mutexattr_t = .init()

    @inlinable
    public static func create(type: MutexType? = nil) -> Result<Self, Errno> {
      var attr = Self.init()
      return SyscallUtilities.errnoOrZeroOnReturn {
        pthread_mutexattr_init(&attr.rawValue)
      }.map {
        if let type = type {
          attr.type = type
        }
        return attr
      }
    }

    @inlinable
    public mutating func destroy() {
      PosixThread.call {
        pthread_mutexattr_destroy(&rawValue)
      }
    }

    public struct MutexType: MacroRawRepresentable {

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
  @inlinable
  var prioceiling: Int32 {
    mutating get {
      PosixThread.get {
        pthread_mutex_getprioceiling(&rawValue, $0)
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
  @inlinable
  var prioceiling: Int32 {
    mutating get {
      PosixThread.get {
        pthread_mutexattr_getprioceiling(&rawValue, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setprioceiling(&rawValue, newValue)
      }
    }
  }

  @inlinable
  var `protocol`: Int32 {
    mutating get {
      PosixThread.get {
        pthread_mutexattr_getprotocol(&rawValue, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setprotocol(&rawValue, newValue)
      }
    }
  }

  @inlinable
  var processShared: PosixMutex.ProcessShared {
    mutating get {
      PosixThread.get {
        pthread_mutexattr_getpshared(&rawValue, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_mutexattr_setpshared(&rawValue, newValue.rawValue)
      }
    }
  }

  @inlinable
  var type: MutexType {
    mutating get {
      PosixThread.get {
        pthread_mutexattr_gettype(&rawValue, $0)
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
  @inlinable
  var policy: Policy {
    mutating get {
      PosixThread.get {
        pthread_mutexattr_getpolicy_np(&rawValue, $0)
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

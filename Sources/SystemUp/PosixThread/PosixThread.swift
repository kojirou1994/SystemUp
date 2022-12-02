import SystemLibc
import SystemPackage
import CUtility

public enum PosixThread { }

extension PosixThread {
  public struct ThreadID {
    @usableFromInline
    internal init(rawValue: pthread_t) {
      self.rawValue = rawValue
    }

    @usableFromInline
    internal let rawValue: pthread_t
  }
}

public extension PosixThread.ThreadID {
  @inlinable
  @discardableResult
  func cancel() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cancel(rawValue)
    }
  }

  @inlinable
  @discardableResult
  __consuming func detach() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_detach(rawValue)
    }
  }

  @inlinable
  @discardableResult
  __consuming func join() -> Result<UnsafeMutableRawPointer?, Errno> {
    var value: UnsafeMutableRawPointer?
    return SyscallUtilities.errnoOrZeroOnReturn {
      pthread_join(rawValue, &value)
    }.map { value }
  }
}

public extension PosixThread {

  @inlinable
  static func create(context: UnsafeMutableRawPointer? = nil, attributes: Attributes? = nil,
                     body: @convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?) throws -> ThreadID {
    #if canImport(Darwin)
    let body = unsafeBitCast(body, to: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self)
    let thread = try safeInitialize { thread in
      withOptionalUnsafePointer(to: attributes) { attributes in
        _ = pthread_create(&thread, attributes, body, context)
      }
    }
    #else
    var thread: pthread_t = .init()
    withOptionalUnsafePointer(to: attributes) { attributes in
      _ = pthread_create(&thread, attributes, body, context)
    }
    #endif

    return .init(rawValue: thread)
  }

  @inlinable @inline(__always)
  static func exit(value: UnsafeMutableRawPointer? = nil) -> Never {
    pthread_exit(value)
  }

  /// send a signal to a specified thread
  /// - Parameters:
  ///   - thread: target thread id
  ///   - signal: signal
  @inlinable
  @discardableResult
  static func kill(_ thread: ThreadID, signal: CInt) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_kill(thread.rawValue, signal)
    }
  }

  @inlinable @inline(__always)
  static var current: ThreadID {
    .init(rawValue: pthread_self())
  }
}

// MARK: Pthread Helpers
public extension PosixThread {

  static func create(main: PthreadMain, attributes: Attributes? = nil) throws -> ThreadID {
    try create(context: Unmanaged.passRetained(main).toOpaque(), attributes: attributes) { context in
      let main = Unmanaged<PthreadMain>.fromOpaque(context.unsafelyUnwrapped)
      main.takeUnretainedValue().main()
      main.release()
      return nil
    }
  }

  @discardableResult
  static func detachNewThread(_ block: @escaping () -> Void) throws -> ThreadID {
    var attr = try Attributes()
    defer {
      attr.destroy()
    }
    attr.scope = .system
    attr.detachState = .detached
    return try create(main: .init(main: block), attributes: attr)
  }
}

public final class PthreadMain {
  @inlinable @inline(__always)
  public init(main: @escaping () -> Void) {
    self.main = main
  }

  public let main: () -> Void
}

extension PosixThread.ThreadID: Equatable {
  @inlinable @inline(__always)
  public static func == (lhs: Self, rhs: Self) -> Bool {
    pthread_equal(lhs.rawValue, rhs.rawValue) != 0
  }
}

extension PosixThread {
  public struct Attributes {

    @usableFromInline
    internal var rawValue: pthread_attr_t = .init()

    @inlinable
    public init() throws {
      try SyscallUtilities.errnoOrZeroOnReturn {
        pthread_attr_init(&rawValue)
      }.get()
    }

    @inlinable
    public mutating func destroy() {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_destroy(&rawValue)
        }
      }
    }

    public struct DetachState: MacroRawRepresentable {

      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      public let rawValue: Int32

      @_alwaysEmitIntoClient
      public static var detached: Self { .init(macroValue: PTHREAD_CREATE_DETACHED) }
      @_alwaysEmitIntoClient
      public static var joinable: Self { .init(macroValue: PTHREAD_CREATE_JOINABLE) }
    }

    public struct Inheritsched: MacroRawRepresentable {

      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      public let rawValue: Int32

      @_alwaysEmitIntoClient
      public static var inherit: Self { .init(macroValue: PTHREAD_INHERIT_SCHED) }
      @_alwaysEmitIntoClient
      public static var explicit: Self { .init(macroValue: PTHREAD_EXPLICIT_SCHED) }
    }

    public struct SchedParam: RawRepresentable {

      public init(rawValue: sched_param) {
        self.rawValue = rawValue
      }

      public var rawValue: sched_param

      @_alwaysEmitIntoClient
      public static var priorityRange: ClosedRange<Int32> {
        sched_get_priority_min(2)...sched_get_priority_max(2)
      }

    }

    public struct SchedulingPolicy: MacroRawRepresentable {

      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      public let rawValue: Int32

      @_alwaysEmitIntoClient
      public static var fifo: Self { .init(macroValue: SCHED_FIFO) }
      @_alwaysEmitIntoClient
      public static var rr: Self { .init(macroValue: SCHED_RR) }
      @_alwaysEmitIntoClient
      public static var other: Self { .init(macroValue: SCHED_OTHER) }
    }

    public struct Scope: MacroRawRepresentable {

      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      public let rawValue: Int32

      @_alwaysEmitIntoClient
      public static var system: Self { .init(macroValue: PTHREAD_SCOPE_SYSTEM) }
      @_alwaysEmitIntoClient
      public static var process: Self { .init(macroValue: PTHREAD_SCOPE_PROCESS) }
    }
  }
}

public extension PosixThread.Attributes {
  @inlinable
  var stack: UnsafeMutableRawBufferPointer {
    mutating get {
      var start: UnsafeMutableRawPointer?
      var count: Int = 0
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getstack(&rawValue, &start, &count)
        }
      }
      return .init(start: start, count: count)
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_setstack(&rawValue, newValue.baseAddress.unsafelyUnwrapped, newValue.count)
        }
      }
    }
  }

  @inlinable
  var stackSize: Int {
    mutating get {
      var value: Int = 0
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getstacksize(&rawValue, &value)
        }
      }
      return value
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_setstacksize(&rawValue, newValue)
        }
      }
    }
  }

  @inlinable
  var guardSize: Int {
    mutating get {
      var value: Int = 0
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getguardsize(&rawValue, &value)
        }
      }
      return value
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_setguardsize(&rawValue, newValue)
        }
      }
    }
  }

  @inlinable
  var stackAddress: UnsafeMutableRawPointer {
    mutating get {
      var value: UnsafeMutableRawPointer?
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getstackaddr(&rawValue, &value)
        }
      }
      return value!
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_setstackaddr(&rawValue, newValue)
        }
      }
    }
  }

  @inlinable
  var detachState: DetachState {
    mutating get {
      var value: Int32 = 0
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getdetachstate(&rawValue, &value)
        }
      }
      return .init(rawValue: value)
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_setdetachstate(&rawValue, newValue.rawValue)
        }
      }
    }
  }

  @inlinable
  var inheritsched: Inheritsched {
    mutating get {
      var value: Int32 = 0
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getinheritsched(&rawValue, &value)
        }
      }
      return .init(rawValue: value)
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_setinheritsched(&rawValue, newValue.rawValue)
        }
      }
    }
  }

  @inlinable
  var schedParam: SchedParam {
    mutating get {
      var value: sched_param = .init()
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getschedparam(&rawValue, &value)
        }
      }
      return .init(rawValue: value)
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          withUnsafePointer(to: newValue.rawValue) { param in
            pthread_attr_setschedparam(&rawValue, param)
          }
        }
      }
    }
  }

  @inlinable
  var schedPolicy: SchedulingPolicy {
    mutating get {
      var value: Int32 = 0
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getschedpolicy(&rawValue, &value)
        }
      }
      return .init(rawValue: value)
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_setschedpolicy(&rawValue, newValue.rawValue)
        }
      }
    }
  }

  @inlinable
  var scope: Scope {
    mutating get {
      var value: Int32 = 0
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getscope(&rawValue, &value)
        }
      }
      return .init(rawValue: value)
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_setscope(&rawValue, newValue.rawValue)
        }
      }
    }
  }
}

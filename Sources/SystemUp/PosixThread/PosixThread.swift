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
                     body: @convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?) -> Result<ThreadID, Errno> {
    #if canImport(Darwin)
    let body = unsafeBitCast(body, to: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self)
    var thread: pthread_t?
    #else
    var thread: pthread_t = .init()
    #endif

    return SyscallUtilities.errnoOrZeroOnReturn {
      if let attributes = attributes {
        return withCastedUnsafePointer(to: attributes) { pthread_create(&thread, $0, body, context) }
      } else {
        return pthread_create(&thread, nil, body, context)
      }
    }.map {
      #if canImport(Darwin)
      return .init(rawValue: thread.unsafelyUnwrapped)
      #else
      return .init(rawValue: thread)
      #endif
    }

  }

  @inlinable @inline(__always)
  static func exit(value: UnsafeMutableRawPointer? = nil) -> Never {
    pthread_exit(value)
  }

  @inlinable
  static func set(cancelState: CancelState, oldValue: UnsafeMutablePointer<CancelState>? = nil) {
    assertNoFailure {
      SyscallUtilities.errnoOrZeroOnReturn {
        pthread_setcancelstate(cancelState.rawValue, oldValue?.pointer(to: \.rawValue))
      }
    }
  }

  @inlinable
  static func set(cancelType: CancelType, oldValue: UnsafeMutablePointer<CancelType>? = nil) {
    assertNoFailure {
      SyscallUtilities.errnoOrZeroOnReturn {
        pthread_setcanceltype(cancelType.rawValue, oldValue?.pointer(to: \.rawValue))
      }
    }
  }

  @inlinable @inline(__always)
  static func testCancel() {
    pthread_testcancel()
  }

  #if canImport(Darwin)
  /// yield control of the current thread
  @inlinable @inline(__always)
  static func yield() {
    pthread_yield_np()
  }
  #endif

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

  #if !os(Linux)
  @inlinable @inline(__always)
  static var concurrency: Int32 {
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_setconcurrency(newValue)
        }
      }
    }
    get {
      pthread_getconcurrency()
    }
  }
  #endif
}

// MARK: Pthread Helpers
public extension PosixThread {

  static func create(main: ThreadMain, attributes: Attributes? = nil) throws -> ThreadID {
    try create(context: Unmanaged.passRetained(main).toOpaque(), attributes: attributes) { context in
      let main = Unmanaged<ThreadMain>.fromOpaque(context.unsafelyUnwrapped)
      main.takeUnretainedValue().main()
      main.release()
      return nil
    }.get()
  }

  static func detach(_ block: @escaping () -> Void) throws -> ThreadID {
    var attr = try Attributes.create().get()
    defer {
      attr.destroy()
    }
    attr.scope = .system
    attr.detachState = .detached
    return try create(main: .init(main: block), attributes: attr)
  }

  final class ThreadMain {
    @inlinable @inline(__always)
    public init(main: @escaping () -> Void) {
      self.main = main
    }

    public let main: () -> Void
  }
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
    internal init(rawValue: pthread_attr_t) {
      self.rawValue = rawValue
    }

    @usableFromInline
    internal var rawValue: pthread_attr_t

    @inlinable
    public static func create() -> Result<Self, Errno> {
      var attr = Self.init(rawValue: .init())
      return SyscallUtilities.errnoOrZeroOnReturn {
        pthread_attr_init(&attr.rawValue)
      }.map { attr }
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

  public struct CancelState: MacroRawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public var rawValue: Int32

    @_alwaysEmitIntoClient
    public static var enable: Self { .init(macroValue: PTHREAD_CANCEL_ENABLE) }
    @_alwaysEmitIntoClient
    public static var disable: Self { .init(macroValue: PTHREAD_CANCEL_DISABLE) }
  }

  public struct CancelType: MacroRawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public var rawValue: Int32

    @_alwaysEmitIntoClient
    public static var deferred: Self { .init(macroValue: PTHREAD_CANCEL_DEFERRED) }
    @_alwaysEmitIntoClient
    public static var asynchronous: Self { .init(macroValue: PTHREAD_CANCEL_ASYNCHRONOUS) }
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

  #if !os(Linux)
  @inlinable
  var stackAddress: UnsafeMutableRawPointer {
    mutating get {
      var value: UnsafeMutableRawPointer?
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_getstackaddr(&rawValue, &value)
        }
      }
      return value.unsafelyUnwrapped
    }
    set {
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          pthread_attr_setstackaddr(&rawValue, newValue)
        }
      }
    }
  }
  #endif

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

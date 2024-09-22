import SystemLibc
import SystemPackage
import CUtility

public enum PosixThread { }

extension PosixThread {
  public struct ThreadID: ~Copyable {
    @usableFromInline
    internal init(rawValue: pthread_t) {
      self.rawValue = rawValue
    }

    @usableFromInline
    internal let rawValue: pthread_t
  }
}

public extension PosixThread.ThreadID {
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func cancel() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cancel(rawValue)
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  consuming func detach() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_detach(rawValue)
    }
  }

  @available(*, noasync)
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  consuming func join() -> Result<UnsafeMutableRawPointer?, Errno> {
    var value: UnsafeMutableRawPointer?
    return SyscallUtilities.errnoOrZeroOnReturn {
      pthread_join(rawValue, &value)
    }.map { value }
  }

  /// send a signal to a specified thread
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func send(signal: Signal) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_kill(rawValue, signal.rawValue)
    }
  }
}

public extension PosixThread {

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exit(value: UnsafeMutableRawPointer? = nil) -> Never {
    pthread_exit(value)
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(cancelState: CancelState, oldValue: UnsafeMutablePointer<CancelState>? = nil) {
    PosixThread.call {
      pthread_setcancelstate(cancelState.rawValue, oldValue?.pointer(to: \.rawValue))
    }
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(cancelType: CancelType, oldValue: UnsafeMutablePointer<CancelType>? = nil) {
    PosixThread.call {
      pthread_setcanceltype(cancelType.rawValue, oldValue?.pointer(to: \.rawValue))
    }
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func testCancel() {
    pthread_testcancel()
  }

  #if canImport(Darwin)
  /// yield control of the current thread
  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func yield() {
    pthread_yield_np()
  }
  #endif

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var current: ThreadID {
    .init(rawValue: pthread_self())
  }

  #if !os(Linux)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var concurrency: Int32 {
    set {
      PosixThread.call {
        pthread_setconcurrency(newValue)
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

  @inlinable @inline(__always)
  internal static func create(context: UnsafeMutableRawPointer? = nil, attributes: UnsafePointer<pthread_attr_t>?,
                     body: @convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?) throws(Errno) -> pthread_t {
    #if canImport(Darwin)
    let body = unsafeBitCast(body, to: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self)
    var thread: pthread_t?
    #else
    var thread: pthread_t = .init()
    #endif

    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_create(&thread, attributes, body, context)
    }.get()

    #if canImport(Darwin)
    return thread.unsafelyUnwrapped
    #else
    return thread
    #endif
  }

  @inlinable @inline(__always)
  internal static func create(attributes: UnsafePointer<pthread_attr_t>?, _ block: @escaping @Sendable () -> Void) throws(Errno) -> pthread_t {
    try create(context: Unmanaged.passRetained(block as AnyObject).toOpaque(), attributes: attributes) { context in
      let block = Unmanaged<AnyObject>.fromOpaque(context.unsafelyUnwrapped)
      (block.takeUnretainedValue() as! (@Sendable () -> Void))()
      block.release()
      return nil
    }
  }

  @inlinable
  static func create(_ block: @escaping @Sendable () -> Void) throws(Errno) -> ThreadID {
    try .init(rawValue: create(attributes: nil, block))
  }

  @inlinable
  static func create(attributes: borrowing Attributes, _ block: @escaping @Sendable () -> Void) throws(Errno) -> ThreadID {
    try .init(rawValue: withUnsafePointer(to: attributes.rawValue) { attributes throws(Errno) in
      try create(attributes: attributes, block)
    })
  }

  @discardableResult
  static func detach(_ block: @escaping @Sendable () -> Void) throws(Errno) -> ThreadID {
    var attr = try Attributes()
    defer {
      attr.destroy()
    }
    attr.scope = .system
    attr.detachState = .detached
    return try create(attributes: attr, block)
  }
}

extension PosixThread.ThreadID {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func equals(to another: borrowing Self) -> Bool {
    pthread_equal(rawValue, another.rawValue) != 0
  }
}

extension PosixThread {
  public struct Attributes: ~Copyable {

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() throws(Errno) {
      try SyscallUtilities.errnoOrZeroOnReturn {
        pthread_attr_init(&rawValue)
      }.get()
    }

    @usableFromInline
    internal var rawValue: pthread_attr_t = .init()

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public mutating func destroy() {
      PosixThread.call {
        pthread_attr_destroy(&rawValue)
      }
    }

    public struct DetachState: MacroRawRepresentable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
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
      @_alwaysEmitIntoClient @inlinable @inline(__always)
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
      @_alwaysEmitIntoClient @inlinable @inline(__always)
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
      @_alwaysEmitIntoClient @inlinable @inline(__always)
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
      @_alwaysEmitIntoClient @inlinable @inline(__always)
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
    @_alwaysEmitIntoClient @inlinable @inline(__always)
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
    @_alwaysEmitIntoClient @inlinable @inline(__always)
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
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var stack: UnsafeMutableRawBufferPointer {
    mutating get {
      var start: UnsafeMutableRawPointer?
      var count: Int = 0
      PosixThread.call {
        pthread_attr_getstack(&rawValue, &start, &count)
      }
      return .init(start: start, count: count)
    }
    set {
      PosixThread.call { pthread_attr_setstack(&rawValue, newValue.baseAddress.unsafelyUnwrapped, newValue.count) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var stackSize: Int {
    mutating get {
      PosixThread.get { pthread_attr_getstacksize(&rawValue, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setstacksize(&rawValue, newValue) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var guardSize: Int {
    mutating get {
      PosixThread.get { pthread_attr_getguardsize(&rawValue, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setguardsize(&rawValue, newValue) }
    }
  }

  #if !os(Linux)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var stackAddress: UnsafeMutableRawPointer {
    mutating get {
      PosixThread.get { pthread_attr_getstackaddr(&rawValue, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setstackaddr(&rawValue, newValue) }
    }
  }
  #endif

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var detachState: DetachState {
    mutating get {
      PosixThread.get { pthread_attr_getdetachstate(&rawValue, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setdetachstate(&rawValue, newValue.rawValue) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var inheritsched: Inheritsched {
    mutating get {
      PosixThread.get { pthread_attr_getinheritsched(&rawValue, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setinheritsched(&rawValue, newValue.rawValue) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var schedParam: SchedParam {
    mutating get {
      var value: sched_param = .init()
      PosixThread.call {
        pthread_attr_getschedparam(&rawValue, &value)
      }
      return .init(rawValue: value)
    }
    set {
      PosixThread.call {
        withUnsafePointer(to: newValue.rawValue) { param in
          pthread_attr_setschedparam(&rawValue, param)
        }
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var schedPolicy: SchedulingPolicy {
    mutating get {
      PosixThread.get { pthread_attr_getschedpolicy(&rawValue, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setschedpolicy(&rawValue, newValue.rawValue) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var scope: Scope {
    mutating get {
      PosixThread.get { pthread_attr_getscope(&rawValue, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setscope(&rawValue, newValue.rawValue) }
    }
  }
}

// MARK: Utility
extension PosixThread {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func get<T, R>(_ body: (UnsafeMutablePointer<R>) -> Int32) -> T {
    return withUnsafeTemporaryAllocation(of: R.self, capacity: 1) { dst in
      assertNoFailure {
        SyscallUtilities.errnoOrZeroOnReturn {
          body(dst.baseAddress.unsafelyUnwrapped)
        }
      }
      return unsafeBitCast(dst[0], to: T.self)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func call(_ body: () -> Int32) {
    assertNoFailure {
      SyscallUtilities.errnoOrZeroOnReturn(body)
    }
  }

}

// MARK: Darwin QOS
#if canImport(Darwin)
public extension PosixThread {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(qualityOfService qos: PosixSpawn.Attributes.QualityOfService, relativePriority: Int32) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_set_qos_class_self_np(qos, relativePriority)
    }
  }
}

public extension PosixThread.ThreadID {

  struct QualityOfServiceOverride: ~Copyable {
    @usableFromInline
    let rawValue: pthread_override_t

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    init(rawValue: pthread_override_t) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public consuming func end() {
      pthread_override_qos_class_end_np(rawValue)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getQualityOfService(to qos: UnsafeMutablePointer<PosixSpawn.Attributes.QualityOfService>?, relativePriority: UnsafeMutablePointer<Int32>? = nil) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_get_qos_class_np(rawValue, qos, relativePriority)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func overrideStart(qualityOfService qos: PosixSpawn.Attributes.QualityOfService, relativePriority: Int32) throws -> QualityOfServiceOverride {
    if let v = unsafeBitCast(pthread_override_qos_class_start_np(rawValue, qos, relativePriority), to: OpaquePointer?.self) {
      return .init(rawValue: v)
    } else {
      throw Errno.invalidArgument
    }
  }

}

public extension PosixThread.Attributes {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func getQualityOfService(to qos: UnsafeMutablePointer<PosixSpawn.Attributes.QualityOfService>?, relativePriority: UnsafeMutablePointer<Int32>? = nil) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_attr_get_qos_class_np(&rawValue, qos, relativePriority)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func set(qualityOfService qos: PosixSpawn.Attributes.QualityOfService, relativePriority: Int32) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_attr_set_qos_class_np(&rawValue, qos, relativePriority)
    }
  }
}
#endif

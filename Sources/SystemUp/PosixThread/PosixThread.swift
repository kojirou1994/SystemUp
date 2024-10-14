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

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func create(data: UnsafeMutableRawPointer? = nil, attributes: UnsafePointer<pthread_attr_t>?, _ body: @convention(c) (_ data: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?) throws(Errno) -> ThreadID {
    #if canImport(Darwin)
    let body = unsafeBitCast(body, to: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self)
    var thread: pthread_t?
    #elseif os(Linux)
    var thread: pthread_t = .init()
    #endif

    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_create(&thread, attributes, body, data)
    }.get()

    #if canImport(Darwin)
    return .init(rawValue: thread.unsafelyUnwrapped)
    #else
    return .init(rawValue: thread)
    #endif
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  internal static func create(attributes: UnsafePointer<pthread_attr_t>?, _ block: @escaping @Sendable () -> Void) throws(Errno) -> ThreadID {
    try create(data: Unmanaged.passRetained(block as AnyObject).toOpaque(), attributes: attributes) { context in
      let block = Unmanaged<AnyObject>.fromOpaque(context.unsafelyUnwrapped)
      (block.takeUnretainedValue() as! (@Sendable () -> Void))()
      block.release()
      return nil
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func create(_ block: @escaping @Sendable () -> Void) throws(Errno) -> ThreadID {
    try create(attributes: nil, block)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func create(attributes: borrowing Attributes, _ block: @escaping @Sendable () -> Void) throws(Errno) -> ThreadID {
    try create(attributes: attributes.rawAddress, block)
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func detach(_ block: @escaping @Sendable () -> Void) throws(Errno) -> ThreadID {
    var attr = try Attributes()
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
  public struct Attributes: ~Copyable, @unchecked Sendable {

    @usableFromInline
    internal let rawAddress: UnsafeMutablePointer<pthread_attr_t>

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() throws(Errno) {
      rawAddress = .allocate(capacity: 1)
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
        pthread_attr_init(rawAddress)
      }.get()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    internal func destroy() {
      PosixThread.call {
        pthread_attr_destroy(rawAddress)
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
    get {
      var start: UnsafeMutableRawPointer?
      var count: Int = 0
      PosixThread.call {
        pthread_attr_getstack(rawAddress, &start, &count)
      }
      return .init(start: start, count: count)
    }
    set {
      PosixThread.call { pthread_attr_setstack(rawAddress, newValue.baseAddress.unsafelyUnwrapped, newValue.count) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var stackSize: Int {
    get {
      PosixThread.get { pthread_attr_getstacksize(rawAddress, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setstacksize(rawAddress, newValue) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var guardSize: Int {
    get {
      PosixThread.get { pthread_attr_getguardsize(rawAddress, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setguardsize(rawAddress, newValue) }
    }
  }

  #if !os(Linux)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var stackAddress: UnsafeMutableRawPointer {
    get {
      PosixThread.get { pthread_attr_getstackaddr(rawAddress, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setstackaddr(rawAddress, newValue) }
    }
  }
  #endif

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var detachState: DetachState {
    get {
      PosixThread.get { pthread_attr_getdetachstate(rawAddress, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setdetachstate(rawAddress, newValue.rawValue) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var inheritsched: Inheritsched {
    get {
      PosixThread.get { pthread_attr_getinheritsched(rawAddress, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setinheritsched(rawAddress, newValue.rawValue) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var schedParam: SchedParam {
    get {
      var value: sched_param = .init()
      PosixThread.call {
        pthread_attr_getschedparam(rawAddress, &value)
      }
      return .init(rawValue: value)
    }
    set {
      PosixThread.call {
        withUnsafePointer(to: newValue.rawValue) { param in
          pthread_attr_setschedparam(rawAddress, param)
        }
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var schedPolicy: SchedulingPolicy {
    get {
      PosixThread.get { pthread_attr_getschedpolicy(rawAddress, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setschedpolicy(rawAddress, newValue.rawValue) }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var scope: Scope {
    get {
      PosixThread.get { pthread_attr_getscope(rawAddress, $0) }
    }
    set {
      PosixThread.call { pthread_attr_setscope(rawAddress, newValue.rawValue) }
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
  func overrideStart(qualityOfService qos: PosixSpawn.Attributes.QualityOfService, relativePriority: Int32) throws(Errno) -> QualityOfServiceOverride {
    if let v = unsafeBitCast(pthread_override_qos_class_start_np(rawValue, qos, relativePriority), to: OpaquePointer?.self) {
      return .init(rawValue: v)
    } else {
      throw Errno.invalidArgument
    }
  }

}

public extension PosixThread.Attributes {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getQualityOfService(to qos: UnsafeMutablePointer<PosixSpawn.Attributes.QualityOfService>?, relativePriority: UnsafeMutablePointer<Int32>? = nil) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_attr_get_qos_class_np(rawAddress, qos, relativePriority)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func set(qualityOfService qos: PosixSpawn.Attributes.QualityOfService, relativePriority: Int32) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_attr_set_qos_class_np(rawAddress, qos, relativePriority)
    }
  }
}
#endif

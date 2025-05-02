import SystemLibc
import SystemPackage
import CUtility

// seconds since 1970
public struct TimeT: RawRepresentable, Sendable, BitwiseCopyable {
  public var rawValue: time_t
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: time_t) {
    assert(rawValue != -1, "impossible")
    self.rawValue = rawValue
  }
}

public extension TimeT {

  static var now: Self { .init(rawValue: SystemLibc.time(nil)) }
  mutating func getNow() {
    SystemLibc.time(&rawValue)
    assert(rawValue != -1, "impossible")
  }

  /// The difftime() function returns the difference between two calendar times, (time1 - time0), expressed in seconds.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func diff(to r: Self) -> Double {
    difftime(self.rawValue, r.rawValue)
  }
  /*
   The ctime() function adjusts the time value for the current time zone, in the same manner as localtime().  It returns a pointer to a 26-character
   string of the form:

   Thu Nov 24 18:22:48 1986\n\0

   All of the fields have constant width.
   */
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func ctime() throws(Errno) -> StaticCString {
    try .init(cString: SyscallUtilities.unwrap {
      withUnsafePointer(to: rawValue) { time in
        SystemLibc.ctime(time)
      }
    }.get())
  }
  
  /// The result is returned in a static buffer
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func localtime() throws(Errno) -> TimeFields {
    try .init(SyscallUtilities.unwrap {
      withUnsafePointer(to: rawValue) { time in
        SystemLibc.localtime(time)
      }
    }.get())
  }

  /*
   The function gmtime() also converts the time value, but makes no time zone adjustment.
   */
  /// The result is returned in a static buffer
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func gmtime() throws(Errno) -> TimeFields {
    try .init(SyscallUtilities.unwrap {
      withUnsafePointer(to: rawValue) { time in
        SystemLibc.gmtime(time)
      }
    }.get())
  }

  /// The ctime_r() function provides the same functionality as ctime(), except that the caller must provide the output buffer buf (which must be at least
  /// 26 characters long) to store the result.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func ctime(to out: UnsafeMutablePointer<CChar>) throws(Errno) {
    _ = try SyscallUtilities.unwrap {
      withUnsafePointer(to: rawValue) { time in
        SystemLibc.ctime_r(time, out)
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func localtime(to out: inout ManagedTimeFields) throws(Errno) {
    _ = try SyscallUtilities.unwrap {
      withUnsafePointer(to: rawValue) { time in
        SystemLibc.localtime_r(time, out.fields.rawAddress)
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func gmtime(to out: inout ManagedTimeFields) throws(Errno) {
    _ = try SyscallUtilities.unwrap {
      withUnsafePointer(to: rawValue) { time in
        SystemLibc.gmtime_r(time, out.fields.rawAddress)
      }
    }.get()
  }
}

// TODO: @_rawLayout(...)
public struct Timespec: RawRepresentable, Sendable, BitwiseCopyable {
  public var rawValue: timespec
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: timespec) {
    self.rawValue = rawValue
  }
}

public extension Timespec {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var seconds: Int {
    _read { yield rawValue.tv_sec }
    _modify { yield &rawValue.tv_sec }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var nanoseconds: Int {
    _read { yield rawValue.tv_nsec }
    _modify { yield &rawValue.tv_nsec }
  }
}

// TODO: @_rawLayout(...)
public struct Timeval: RawRepresentable, Sendable, BitwiseCopyable {
  public var rawValue: timeval
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: timeval) {
    self.rawValue = rawValue
  }
}

public extension Timeval {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var seconds: Int {
    _read { yield rawValue.tv_sec }
    _modify { yield &rawValue.tv_sec }
  }

#if canImport(Darwin)
  typealias USeconds = __darwin_suseconds_t
#elseif os(Linux)
  typealias USeconds = __suseconds_t
#endif

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var microseconds: USeconds {
    _read { yield rawValue.tv_usec }
    _modify { yield &rawValue.tv_usec }
  }
}

// TODO: @_rawLayout(...)
public struct Timezone: RawRepresentable, Sendable, BitwiseCopyable {
  public var rawValue: timezone
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: timezone) {
    self.rawValue = rawValue
  }
}

public extension Timezone {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var minuteswest: Int32 {
    _read { yield rawValue.tz_minuteswest }
    _modify { yield &rawValue.tz_minuteswest }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var dsttime: Int32 {
    _read { yield rawValue.tz_dsttime }
    _modify { yield &rawValue.tz_dsttime }
  }
}

public struct PosixClock: RawRepresentable, Sendable {
  public var rawValue: clockid_t
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: clockid_t) {
    self.rawValue = rawValue
  }
}

public extension PosixClock {
  /// the system's real time (i.e. wall time) clock, expressed as the amount of time since the Epoch.  This is the same as the value returned by gettimeofday(2).
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var realtime: Self { .init(rawValue: CLOCK_REALTIME) }

  /// clock that increments monotonically, tracking the time since an arbitrary point, and will continue to increment while the system is asleep.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var monotonic: Self { .init(rawValue: CLOCK_MONOTONIC) }

  /// clock that increments monotonically, tracking the time since an arbitrary point like CLOCK_MONOTONIC.  However, this clock is
  /// unaffected by frequency or time adjustments.  It should not be compared to other system time sources.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var monotonicRaw: Self { .init(rawValue: CLOCK_MONOTONIC_RAW) }

  #if canImport(Darwin)
  /// like CLOCK_MONOTONIC_RAW, but reads a value cached by the system at context switch.  This can be read faster, but at a loss of
  /// accuracy as it may return values that are milliseconds old.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var monotonicRawApprox: Self { .init(rawValue: CLOCK_MONOTONIC_RAW_APPROX) }

  /// clock that increments monotonically, in the same manner as CLOCK_MONOTONIC_RAW, but that does not increment while the system is
  /// asleep.  The returned value is identical to the result of mach_absolute_time() after the appropriate mach_timebase conversion is
  /// applied.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var upTimeRaw: Self { .init(rawValue: CLOCK_UPTIME_RAW) }

  /// like CLOCK_UPTIME_RAW, but reads a value cached by the system at context switch.  This can be read faster, but at a loss of
  /// accuracy as it may return values that are milliseconds old.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var upTimeRawApprox: Self { .init(rawValue: CLOCK_UPTIME_RAW_APPROX) }
  #endif

  /// clock that tracks the amount of CPU (in user- or kernel-mode) used by the calling process.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var processCpuTime: Self { .init(rawValue: CLOCK_PROCESS_CPUTIME_ID) }

  /// clock that tracks the amount of CPU (in user- or kernel-mode) used by the calling thread.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var threadCpuTime: Self { .init(rawValue: CLOCK_THREAD_CPUTIME_ID) }
}

public extension PosixClock {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getTime(to output: inout Timespec) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      clock_gettime(rawValue, &output.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func set(time: Timespec) throws(Errno) {
    // Only the CLOCK_REALTIME clock can be set, and only the superuser may do so.
    assert(self == .realtime)
    try SyscallUtilities.voidOrErrno {
      withUnsafePointer(to: time.rawValue) { time in
        clock_settime(rawValue, time)
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getResolution(to output: inout Timespec) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      clock_getres(rawValue, &output.rawValue)
    }.get()
  }
}

// TODO: @_rawLayout(...)

public struct ManagedTimeFields: ~Copyable {
  public let fields: TimeFields

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() {
    fields = .init(.allocate(capacity: 1))
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    fields.rawAddress.deallocate()
  }
}

public struct TimeFields: ~Copyable {
  @usableFromInline
  internal let rawAddress: UnsafeMutablePointer<tm>

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  internal init(_ rawAddress: UnsafeMutablePointer<tm>) {
    self.rawAddress = rawAddress
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func withTemporaryTM<R: ~Copyable, E: Error>(_ body: (inout Self) throws(E) -> R) throws(E) -> R {
    try toTypedThrows(E.self) {
      try withUnsafeTemporaryAllocation(of: tm.self, capacity: 1) { buff in
        var v = Self(buff.baseAddress.unsafelyUnwrapped)
        defer {
          assert(v.rawAddress == buff.baseAddress, "Should never happen!")
        }
        return try body(&v)
      }
    }
  }

}

public extension TimeFields {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func asctime() throws(Errno) -> StaticCString {
    try .init(cString: SyscallUtilities.unwrap {
      SystemLibc.asctime(rawAddress)
    }.get())
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func asctime(to out: UnsafeMutablePointer<CChar>) throws(Errno) {
    _ = try SyscallUtilities.unwrap {
      SystemLibc.asctime_r(rawAddress, out)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func mktime() -> TimeT? {
    let v = SystemLibc.mktime(rawAddress)
    if v == -1 {
      return nil
    }
    return .init(rawValue: v)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func timegm() -> TimeT? {
    let v = SystemLibc.timegm(rawAddress)
    if v == -1 {
      return nil
    }
    return .init(rawValue: v)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func timelocal() -> TimeT? {
    let v = SystemLibc.timelocal(rawAddress)
    if v == -1 {
      return nil
    }
    return .init(rawValue: v)
  }
}

public enum TimeOfDay {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func get(t: UnsafeMutablePointer<Timeval>?, tz: UnsafeMutablePointer<Timezone>?) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.gettimeofday(unsafeBitCast(t?.pointer(to: \.rawValue), to: UnsafeMutablePointer<timeval>.self), tz?.pointer(to: \.rawValue))
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func set(t: Timeval, tz: Timezone) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      withUnsafePointer(to: t.rawValue) { t in
        withUnsafePointer(to: tz.rawValue) { tz in
          SystemLibc.settimeofday(t, tz)
        }
      }
    }.get()
  }
}

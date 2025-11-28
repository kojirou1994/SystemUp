import SystemLibc

public extension SystemCall {
  
  /// suspends execution of the calling thread until either seconds seconds have elapsed or a signal is delivered to the thread and
  /// its action is to invoke a signal-catching function or to terminate the thread or process.  System activity may lengthen the sleep by an
  /// indeterminate amount.
  /// - Parameter seconds: seconds
  /// - Returns: 0 if the requested time has elapsed. If the sleep() function returns due to the delivery of a signal, the value returned will be the unslept amount (the requested time minus the time actually slept) in seconds.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func sleep(seconds: UInt32) -> UInt32 {
    SystemLibc.sleep(seconds)
  }
  
  /// suspends execution of the calling thread until either microseconds microseconds have elapsed or a signal is delivered to the
  /// thread and its action is to invoke a signal-catching function or to terminate the process.  System activity or limitations may lengthen the sleep by
  /// an indeterminate amount.
  /// - Parameter microseconds: microseconds
  @available(*, deprecated, message: "The usleep() function is obsolescent.  Use nanosleep(2) instead.")
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func usleep(microseconds: UInt32) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.usleep(microseconds)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func nanosleep(rqtp: Timespec, rmtp: UnsafeMutablePointer<Timespec>?) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      withUnsafePointer(to: rqtp.rawValue) { rqtp in
        SystemLibc.nanosleep(rqtp, rmtp?.pointer(to: \.rawValue))
      }
    }.get()
  }
}

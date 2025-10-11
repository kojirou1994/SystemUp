import SystemLibc
import SystemPackage

public struct PosixCondition: ~Copyable, @unchecked Sendable {

  @usableFromInline
  internal let rawAddress: UnsafeMutablePointer<pthread_cond_t> = .allocate(capacity: 1)

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(attributes: borrowing Attributes) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_init(rawAddress, attributes.rawAddress)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_init(rawAddress, nil)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    PosixThread.call {
      pthread_cond_destroy(rawAddress)
    }
    rawAddress.deallocate()
  }
}

public extension PosixCondition {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func broadcast() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_broadcast(rawAddress)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func signal() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_signal(rawAddress)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func wait(mutex: inout PosixMutex) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_wait(rawAddress, mutex.rawAddress)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func timedwait(mutex: inout PosixMutex, abstime: Timespec) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      withUnsafePointer(to: abstime.rawValue) { abstime in
        pthread_cond_timedwait(rawAddress, mutex.rawAddress, abstime)
      }
    }.get()
  }
}

extension PosixCondition {
  public struct Attributes: ~Copyable {

    @usableFromInline
    internal let rawAddress: UnsafeMutablePointer<pthread_condattr_t> = .allocate(capacity: 1)

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
        pthread_condattr_init(rawAddress)
      }.get()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    internal func destroy() {
      PosixThread.call {
        pthread_condattr_destroy(rawAddress)
      }
    }
  }

}

public extension PosixCondition.Attributes {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    get {
      PosixThread.get {
        pthread_condattr_getpshared(rawAddress, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_condattr_setpshared(rawAddress, newValue.rawValue)
      }
    }
  }

}

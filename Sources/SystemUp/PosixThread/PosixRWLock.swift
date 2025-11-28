import SystemLibc

public struct PosixRWLock: ~Copyable {

  @usableFromInline
  internal let rawAddress: UnsafeMutablePointer<pthread_rwlock_t> = .allocate(capacity: 1)

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(attributes: borrowing Attributes) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_init(rawAddress, attributes.rawAddress)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_init(rawAddress, nil)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    PosixThread.call {
      pthread_rwlock_destroy(rawAddress)
    }
    rawAddress.deallocate()
  }
}

public extension PosixRWLock {


  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func lockRead() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_rdlock(rawAddress)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func tryLockRead() -> Bool {
    pthread_rwlock_tryrdlock(rawAddress) == 0
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func lockWrite() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_wrlock(rawAddress)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func tryLockWrite() -> Bool {
    pthread_rwlock_trywrlock(rawAddress) == 0
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func unlock() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_unlock(rawAddress)
    }.get()
  }
}

extension PosixRWLock {
  public struct Attributes: ~Copyable {

    @usableFromInline
    internal let rawAddress: UnsafeMutablePointer<pthread_rwlockattr_t> = .allocate(capacity: 1)

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
        pthread_rwlockattr_init(rawAddress)
      }.get()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    internal func destroy() {
      PosixThread.call {
        pthread_rwlockattr_destroy(rawAddress)
      }
    }

  }
}

public extension PosixRWLock.Attributes {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    get {
      PosixThread.get {
        pthread_rwlockattr_getpshared(rawAddress, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_rwlockattr_setpshared(rawAddress, newValue.rawValue)
      }
    }
  }
}

import SystemLibc
import SwiftExperimental

@_staticExclusiveOnly
public struct PosixRWLock: ~Copyable, @unchecked Sendable {

  @usableFromInline
  internal let value: StableAddress<pthread_rwlock_t> = .undefined

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(attributes: borrowing Attributes) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_init(value._address, attributes.value._address)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_init(value._address, nil)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    PosixThread.call {
      pthread_rwlock_destroy(value._address)
    }
  }
}

public extension PosixRWLock {


  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func lockRead() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_rdlock(value._address)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func tryLockRead() -> Bool {
    pthread_rwlock_tryrdlock(value._address) == 0
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func lockWrite() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_wrlock(value._address)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func tryLockWrite() -> Bool {
    pthread_rwlock_trywrlock(value._address) == 0
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func unlock() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_unlock(value._address)
    }.get()
  }
}

extension PosixRWLock {
  @_staticExclusiveOnly
  public struct Attributes: ~Copyable {

    @usableFromInline
    internal let value: StableAddress<pthread_rwlockattr_t> = .undefined

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() throws(Errno) {
      try SyscallUtilities.errnoOrZeroOnReturn {
        pthread_rwlockattr_init(value._address)
      }.get()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    deinit {
      PosixThread.call {
        pthread_rwlockattr_destroy(value._address)
      }
    }

  }
}

public extension PosixRWLock.Attributes {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    get {
      PosixThread.get {
        pthread_rwlockattr_getpshared(value._address, $0)
      }
    }
    nonmutating set {
      PosixThread.call {
        pthread_rwlockattr_setpshared(value._address, newValue.rawValue)
      }
    }
  }
}

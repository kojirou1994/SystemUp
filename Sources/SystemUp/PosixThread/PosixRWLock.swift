import SystemLibc
import SystemPackage
import CUtility

public struct PosixRWLock: ~Copyable {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(attributes: borrowing Attributes) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      withUnsafePointer(to: attributes.rawValue) { pthread_rwlock_init(&rawValue, $0) }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_init(&rawValue, nil)
    }.get()
  }

  @usableFromInline
  internal var rawValue: pthread_rwlock_t = .init()
}

public extension PosixRWLock {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func destroy() {
    PosixThread.call {
      pthread_rwlock_destroy(&rawValue)
    }
  }

  @available(*, noasync)
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func lockRead() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_rdlock(&rawValue)
    }
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func tryLockRead() -> Bool {
    pthread_rwlock_tryrdlock(&rawValue) == 0
  }

  @available(*, noasync)
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func lockWrite() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_wrlock(&rawValue)
    }
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func tryLockWrite() -> Bool {
    pthread_rwlock_trywrlock(&rawValue) == 0
  }

  @available(*, noasync)
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func unlock() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_unlock(&rawValue)
    }
  }
}

extension PosixRWLock {
  public struct Attributes: ~Copyable {
    
    @usableFromInline
    internal var rawValue: pthread_rwlockattr_t = .init()
    
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() throws(Errno) {
      try SyscallUtilities.errnoOrZeroOnReturn {
        pthread_rwlockattr_init(&rawValue)
      }.get()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public consuming func destroy() {
      PosixThread.call {
        pthread_rwlockattr_destroy(&rawValue)
      }
    }
  }
}

public extension PosixRWLock.Attributes {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    get {
      withUnsafePointer(to: rawValue) { attr in
        PosixThread.get {
          pthread_rwlockattr_getpshared(attr, $0)
        }
      }
    }
    set {
      PosixThread.call {
        pthread_rwlockattr_setpshared(&rawValue, newValue.rawValue)
      }
    }
  }
}

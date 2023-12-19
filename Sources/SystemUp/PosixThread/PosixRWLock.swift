import SystemLibc
import SystemPackage
import CUtility

public struct PosixRWLock {
  @usableFromInline
  internal init() {}

  @usableFromInline
  internal var rawValue: pthread_rwlock_t = .init()
}

public extension PosixRWLock {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func create(attributes: Attributes? = nil) -> Result<Self, Errno> {
    var lock = Self.init()
    return SyscallUtilities.errnoOrZeroOnReturn {
      if let attributes = attributes {
        return withCastedUnsafePointer(to: attributes) { pthread_rwlock_init(&lock.rawValue, $0) }
      } else {
        return pthread_rwlock_init(&lock.rawValue, nil)
      }
    }.map { lock }
  }

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
  public struct Attributes {
    @usableFromInline
    internal init() {}
    
    @usableFromInline
    internal var rawValue: pthread_rwlockattr_t = .init()
    
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public static func create() -> Result<Self, Errno> {
      var attr = Self.init()
      return SyscallUtilities.errnoOrZeroOnReturn {
        pthread_rwlockattr_init(&attr.rawValue)
      }.map {
        return attr
      }
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public mutating func destroy() {
      PosixThread.call {
        pthread_rwlockattr_destroy(&rawValue)
      }
    }
  }
}

public extension PosixRWLock.Attributes {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    mutating get {
      PosixThread.get {
        pthread_rwlockattr_getpshared(&rawValue, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_rwlockattr_setpshared(&rawValue, newValue.rawValue)
      }
    }
  }
}

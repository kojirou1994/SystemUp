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

  @inlinable
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

  @inlinable
  mutating func destroy() {
    PosixThread.call {
      pthread_rwlock_destroy(&rawValue)
    }
  }

  @inlinable
  @discardableResult
  mutating func lockRead() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_rdlock(&rawValue)
    }
  }

  @inlinable
  mutating func tryLockRead() -> Bool {
    pthread_rwlock_tryrdlock(&rawValue) == 0
  }

  @inlinable
  @discardableResult
  mutating func lockWrite() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_rwlock_wrlock(&rawValue)
    }
  }

  @inlinable
  mutating func tryLockWrite() -> Bool {
    pthread_rwlock_trywrlock(&rawValue) == 0
  }

  @inlinable
  @discardableResult
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
    
    @inlinable
    public static func create() -> Result<Self, Errno> {
      var attr = Self.init()
      return SyscallUtilities.errnoOrZeroOnReturn {
        pthread_rwlockattr_init(&attr.rawValue)
      }.map {
        return attr
      }
    }

    @inlinable
    public mutating func destroy() {
      PosixThread.call {
        pthread_rwlockattr_destroy(&rawValue)
      }
    }
  }
}

public extension PosixRWLock.Attributes {
  @inlinable
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

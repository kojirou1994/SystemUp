import SystemLibc
import SystemPackage
import CUtility

public struct PosixCondition {
  @inlinable
  internal init() {}

  @usableFromInline
  internal var rawValue: pthread_cond_t = .init()
}

public extension PosixCondition {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func create(attributes: Attributes? = nil) -> Result<Self, Errno> {
    var mutex = Self.init()
    return SyscallUtilities.errnoOrZeroOnReturn {
      if let attributes = attributes {
        return withCastedUnsafePointer(to: attributes) { pthread_cond_init(&mutex.rawValue, $0) }
      } else {
        return pthread_cond_init(&mutex.rawValue, nil)
      }
    }.map { mutex }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func destroy() {
    PosixThread.call {
      pthread_cond_destroy(&rawValue)
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func broadcast() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_broadcast(&rawValue)
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func signal() -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_signal(&rawValue)
    }
  }

  @available(*, noasync)
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func wait(mutex: inout PosixMutex) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_wait(&rawValue, &mutex.rawValue)
    }
  }

  @available(*, noasync)
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func timedwait(mutex: inout PosixMutex, abstime: UnsafePointer<timespec>) -> Result<Void, Errno> {
    SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_timedwait(&rawValue, &mutex.rawValue, abstime)
    }
  }
}

extension PosixCondition {
  public struct Attributes {
    @usableFromInline
    internal init() {}

    @usableFromInline
    internal var rawValue: pthread_condattr_t = .init()

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public static func create() -> Result<Self, Errno> {
      var attr = Self.init()
      return SyscallUtilities.errnoOrZeroOnReturn {
        pthread_condattr_init(&attr.rawValue)
      }.map { attr }
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public mutating func destroy() {
      PosixThread.call {
        pthread_condattr_destroy(&rawValue)
      }
    }
  }

}

public extension PosixCondition.Attributes {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    mutating get {
      PosixThread.get {
        pthread_condattr_getpshared(&rawValue, $0)
      }
    }
    set {
      PosixThread.call {
        pthread_condattr_setpshared(&rawValue, newValue.rawValue)
      }
    }
  }

}

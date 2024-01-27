import SystemLibc
import SystemPackage
import CUtility

public struct PosixCondition: ~Copyable {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(attributes: borrowing Attributes) throws {
    try SyscallUtilities.errnoOrZeroOnReturn {
      withUnsafePointer(to: attributes.rawValue) { pthread_cond_init(&rawValue, $0) }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_init(&rawValue, nil)
    }.get()
  }

  @usableFromInline
  internal var rawValue: pthread_cond_t = .init()
}

public extension PosixCondition {

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
  public struct Attributes: ~Copyable {
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() throws {
      try SyscallUtilities.errnoOrZeroOnReturn {
        pthread_condattr_init(&rawValue)
      }.get()
    }

    @usableFromInline
    internal var rawValue: pthread_condattr_t = .init()

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public consuming func destroy() {
      PosixThread.call {
        pthread_condattr_destroy(&rawValue)
      }
    }
  }

}

public extension PosixCondition.Attributes {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    get {
      withUnsafePointer(to: rawValue) { attr in
        PosixThread.get {
          pthread_condattr_getpshared(attr, $0)
        }
      }
    }
    set {
      PosixThread.call {
        pthread_condattr_setpshared(&rawValue, newValue.rawValue)
      }
    }
  }

}

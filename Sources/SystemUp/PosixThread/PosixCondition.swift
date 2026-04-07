import SystemLibc
import SwiftExperimental

@_staticExclusiveOnly
public struct PosixCondition: ~Copyable, @unchecked Sendable {

  @usableFromInline
  internal let value: StableAddress<pthread_cond_t> = .undefined

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(attributes: borrowing Attributes) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_init(value._address, attributes.value._address)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_init(value._address, nil)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    PosixThread.call {
      pthread_cond_destroy(value._address)
    }
  }
}

public extension PosixCondition {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func broadcast() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_broadcast(value._address)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func signal() throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_signal(value._address)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func wait(mutex: borrowing PosixMutex) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      pthread_cond_wait(value._address, mutex.value._address)
    }.get()
  }

  @available(*, noasync)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func timedwait(mutex: borrowing PosixMutex, abstime: Timespec) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      withUnsafePointer(to: abstime.rawValue) { abstime in
        pthread_cond_timedwait(value._address, mutex.value._address, abstime)
      }
    }.get()
  }
}

extension PosixCondition {
  @_staticExclusiveOnly
  public struct Attributes: ~Copyable {

    @usableFromInline
    internal let value: StableAddress<pthread_condattr_t> = .undefined

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() throws(Errno) {
      try SyscallUtilities.errnoOrZeroOnReturn {
        pthread_condattr_init(value._address)
      }.get()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    deinit {
      PosixThread.call {
        pthread_condattr_destroy(value._address)
      }
    }

  }

}

public extension PosixCondition.Attributes {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var processShared: PosixMutex.ProcessShared {
    get {
      PosixThread.get {
        pthread_condattr_getpshared(value._address, $0)
      }
    }
    nonmutating set {
      PosixThread.call {
        pthread_condattr_setpshared(value._address, newValue.rawValue)
      }
    }
  }

}

extension StableAddress {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static var undefined: Self {
    .init(Memory.undefined())
  }
}

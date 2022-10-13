import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import SyscallValue

public extension FilePermissions {
  @inlinable @inline(__always)
  static var directoryDefault: Self { [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute] }

  @inlinable @inline(__always)
  static var fileDefault: Self { [.ownerReadWrite, .groupRead, .otherRead] }

  @inlinable @inline(__always)
  static var executableDefault: Self { [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute] }
}

extension Errno {
  @inlinable @inline(__always)
  public static var current: Self { .init(rawValue: errno) }
}

@inlinable @inline(__always)
public func retryOnInterrupt<T>(_ body: () -> Result<T, Errno>) -> Result<T, Errno> {
  while true {
    switch body() {
    case .success(let v): return .success(v)
    case .failure(.interrupted): break
    case .failure(let e): return .failure(e)
    }
  }
}

@inlinable @inline(__always)
public func zeroOrErrnoOnReturn(_ body: () -> Int32) -> Result<Void, Errno> {
  let code = body()
  if code == 0 {
    return .success(())
  } else {
    return .failure(.init(rawValue: code))
  }
}

@inlinable @inline(__always)
public func voidOrErrno<I: FixedWidthInteger>(_ body: () -> I) -> Result<Void, Errno> {
  valueOrErrno(body).map { _ in () }
}

@inlinable @inline(__always)
public func valueOrErrno<I: FixedWidthInteger>(_ body: () -> I) -> Result<I, Errno> {
  let i = body()
  if i == -1 {
    let err = Errno.current
    return .failure(err)
  } else {
    return .success(i)
  }
}

@inlinable @inline(__always)
public func neverError<R, E>(_ body: () -> Result<R, E>) {
  switch body() {
  case .success: break
  case .failure(let error):
    assertionFailure("Impossible error: \(error)")
  }
}

@inlinable @inline(__always)
internal func syscallUnwrap<T>(_ body: () -> T?) -> Result<T, Errno> {
  if let value  = body() {
    return .success(value)
  } else {
    return .failure(.current)
  }
}

@inlinable @inline(__always)
internal func withOptionalUnsafePointer<T, R, Result>(to v: T?, _ body: (UnsafePointer<R>?) throws -> Result) rethrows -> Result {
  assert(MemoryLayout<T>.size == MemoryLayout<R>.size)
  if let v = v {
    return try withUnsafePointer(to: v) { try body(UnsafeRawPointer($0).assumingMemoryBound(to: R.self)) }
  }
  return try body(nil)
}

extension FileDescriptor {
  public func read<T: SyscallValue>(upToCount count: Int) throws -> T {
    try T.init(capacity: count) { ptr in
      try read(into: UnsafeMutableRawBufferPointer(start: ptr, count: count))
    }
  }

  @inlinable @inline(__always)
  public static var currentWorkingDirectory: Self { .init(rawValue: AT_FDCWD) }
}

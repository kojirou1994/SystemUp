import SystemPackage
import SystemLibc

public enum SyscallUtilities {}

public extension SyscallUtilities {
  @inlinable @inline(__always)
  static func errnoOrZeroOnReturn(_ body: () -> Int32) -> Result<Void, Errno> {
    let code = body()
    if code == 0 {
      return .success(())
    } else {
      return .failure(.init(rawValue: code))
    }
  }

  @inlinable @inline(__always)
  static func retryWhileInterrupted<T>(_ body: () -> Result<T, Errno>) -> Result<T, Errno> {
    while true {
      switch body() {
      case .success(let v): return .success(v)
      case .failure(.interrupted): break
      case .failure(let e): return .failure(e)
      }
    }
  }

  @inlinable @inline(__always)
  static func voidOrErrno<I: FixedWidthInteger>(_ body: () -> I) -> Result<Void, Errno> {
    valueOrErrno(body).map { _ in () }
  }

  @inlinable @inline(__always)
  static func valueOrErrno<I: FixedWidthInteger>(_ body: () -> I) -> Result<I, Errno> {
    let i = body()
    if i == -1 {
      let err = Errno.systemCurrent
      return .failure(err)
    } else {
      return .success(i)
    }
  }

  @inlinable @inline(__always)
  static func unwrap<T>(_ body: () -> T?) -> Result<T, Errno> {
    if let value  = body() {
      return .success(value)
    } else {
      return .failure(.systemCurrent)
    }
  }
}

@inlinable @inline(__always)
public func assertNoFailure<R, E>(file: StaticString = #file, line: UInt = #line, _ body: () -> Result<R, E>) {
  switch body() {
  case .success: break
  case .failure(let error):
    assertionFailure("Impossible Error: \(error)", file: file, line: line)
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

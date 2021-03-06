import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import SyscallValue

extension FilePermissions {
  public static var directoryDefault: Self { [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute] }

  public static var fileDefault: Self { [.ownerReadWrite, .groupRead, .otherRead] }

}

extension Errno {
  static var current: Self { .init(rawValue: errno) }
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

internal func valueOrErrno<I: FixedWidthInteger>(retryOnInterrupt: Bool, _ body: () -> I) -> Result<I, Errno> {
  repeat {
    let i = body()
    if i == -1 {
      let err = Errno.current
      guard retryOnInterrupt && err == .interrupted else {
        return .failure(err)
      }
    } else {
      return .success(i)
    }
  } while true
}

internal func nothingOrErrno<I: FixedWidthInteger>(retryOnInterrupt: Bool, _ body: () -> I) -> Result<Void, Errno> {
  valueOrErrno(retryOnInterrupt: retryOnInterrupt, body).map { _ in () }
}

internal func neverError(_ body: () throws -> Void) {
  do {
    try body()
  } catch {
    assertionFailure("impossible error: \(errno)")
  }
}

extension FileDescriptor {
  public func read<T: SyscallValue>(upToCount count: Int) throws -> T {
    try T.init(capacity: count) { ptr in
      try read(into: UnsafeMutableRawBufferPointer(start: ptr, count: count))
    }
  }

  public static var currentWorkingDirectory: Self { .init(rawValue: AT_FDCWD) }
}

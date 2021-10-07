import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import SyscallValue

extension FilePermissions {
  @_alwaysEmitIntoClient
  public static var directoryDefault: Self { [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute] }

  @_alwaysEmitIntoClient
  public static var fileDefault: Self { [.ownerReadWrite, .groupRead, .otherRead] }

}

extension Errno {
  @_alwaysEmitIntoClient
  static var current: Self { .init(rawValue: errno) }
}

@_alwaysEmitIntoClient
internal func valueOrErrno<I: FixedWidthInteger>(retryOnInterrupt: Bool, _ body: () -> I) -> Result<I, Errno> {
  repeat {
    let i = body()
    guard i != -1 else {
      return .success(i)
    }
    let err = Errno.current
    guard retryOnInterrupt && err == .interrupted else {
      return .failure(err)
    }
  } while true
}

@_alwaysEmitIntoClient
internal func nothingOrErrno<I: FixedWidthInteger>(retryOnInterrupt: Bool, _ body: () -> I) -> Result<Void, Errno> {
  valueOrErrno(retryOnInterrupt: retryOnInterrupt, body).map { _ in () }
}

extension FileDescriptor {
  @_alwaysEmitIntoClient
  public func read<T: SyscallValue>(upToCount count: Int) throws -> T {
    try T.init(capacity: count) { ptr in
      try read(into: UnsafeMutableRawBufferPointer(start: ptr, count: count))
    }
  }

  @_alwaysEmitIntoClient
  public static var currentWorkingDirectory: Self { .init(rawValue: AT_FDCWD) }
}

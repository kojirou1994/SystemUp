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
func valueOrErrno<I: FixedWidthInteger>(
  _ i: I
) throws {
  if i != 0 { throw Errno.current }
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

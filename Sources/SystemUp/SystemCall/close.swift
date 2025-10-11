import SystemPackage
import SystemLibc

public extension SystemCall {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func close(_ fd: FileDescriptor) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.close(fd.rawValue)
    }.get()
  }
}

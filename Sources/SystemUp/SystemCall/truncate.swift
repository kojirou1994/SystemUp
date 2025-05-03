import SystemPackage
import SystemLibc
import CUtility

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func truncate(size: Int, for path: some CStringConvertible) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      path.withUnsafeCString { path in
        SystemLibc.truncate(path, off_t(size))
      }
    }.get()
  }
  
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func truncate(size: Int, for fd: FileDescriptor) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.ftruncate(fd.rawValue, off_t(size))
    }.get()
  }
}

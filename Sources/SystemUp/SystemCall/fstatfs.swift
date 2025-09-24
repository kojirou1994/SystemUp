import SystemPackage
import SystemLibc
import CUtility

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemStatistics(_ fd: FileDescriptor, into s: inout FileSystemStatistics) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      fstatfs(fd.rawValue, &s.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemStatistics(_ path: borrowing some CString, into s: inout FileSystemStatistics) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      path.withUnsafeCString { path in
        statfs(path, &s.rawValue)
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemInformation(_ fd: FileDescriptor, into s: inout FileSystemInformation) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      fstatvfs(fd.rawValue, &s.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemInformation(_ path: borrowing some CString, into s: inout FileSystemInformation) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      path.withUnsafeCString { path in
        statvfs(path, &s.rawValue)
      }
    }.get()
  }
}

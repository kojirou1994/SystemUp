import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemStatistics(_ fd: FileDescriptor, into s: inout FileSystemStatistics) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      fstatfs(fd.rawValue, &s.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemStatistics(_ path: UnsafePointer<CChar>, into s: inout FileSystemStatistics) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      statfs(path, &s.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemInformation(_ fd: FileDescriptor, into s: inout FileSystemInformation) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      fstatvfs(fd.rawValue, &s.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemInformation(_ path: UnsafePointer<CChar>, into s: inout FileSystemInformation) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      statvfs(path, &s.rawValue)
    }.get()
  }
}

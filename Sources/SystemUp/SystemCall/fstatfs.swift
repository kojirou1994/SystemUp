import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemStatistics(_ fd: FileDescriptor, into s: inout FileSystemStatistics) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      fstatfs(fd.rawValue, &s.rawValue)
    }
  }

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemStatistics(_ path: String, into s: inout FileSystemStatistics) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      statfs(path, &s.rawValue)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemInformation(_ fd: FileDescriptor, into s: inout FileSystemInformation) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      fstatvfs(fd.rawValue, &s.rawValue)
    }
  }

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileSystemInformation(_ path: String, into s: inout FileSystemInformation) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      statvfs(path, &s.rawValue)
    }
  }
}

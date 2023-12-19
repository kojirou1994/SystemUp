import CUtility
import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func lock(_ fd: FileDescriptor, flags: FileSyscalls.LockFlags) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      flock(fd.rawValue, flags.rawValue)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func unlock(_ fd: FileDescriptor) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      flock(fd.rawValue, LOCK_UN)
    }
  }
}

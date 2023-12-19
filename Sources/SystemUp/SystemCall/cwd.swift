import SystemPackage
import SystemLibc
import CGeneric
import CUtility

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getWorkingDirectory() -> Result<UnsafeMutablePointer<Int8>, Errno> {
    SyscallUtilities.unwrap {
      SystemLibc.getcwd(nil, 0)
    }
  }

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func changeWorkingDirectory(_ path: String) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.chdir(path)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func changeWorkingDirectory(_ fd: FileDescriptor) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.fchdir(fd.rawValue)
    }
  }
}

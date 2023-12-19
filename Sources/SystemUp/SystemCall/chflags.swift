#if canImport(Darwin)
import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(flags: FileSyscalls.FileFlags, for path: String) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      chflags(path, flags.rawValue)
    }
  }
  
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(flags: FileSyscalls.FileFlags, for fd: FileDescriptor) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      fchflags(fd.rawValue, flags.rawValue)
    }
  }
}
#endif // chflags end

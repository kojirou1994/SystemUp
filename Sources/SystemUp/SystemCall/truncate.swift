import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func truncate(size: Int, for path: UnsafePointer<CChar>) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.truncate(path, off_t(size))
    }
  }
  
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func truncate(size: Int, for fd: FileDescriptor) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.ftruncate(fd.rawValue, off_t(size))
    }
  }
}

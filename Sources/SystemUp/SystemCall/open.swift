import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {
  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func open(_ path: String, relativeTo base: RelativeDirectory = .cwd, _ mode: FileDescriptor.AccessMode,
                   options: FileDescriptor.OpenOptions = .init(),
                   permissions: FilePermissions? = nil) -> Result<FileDescriptor, Errno> {
    
    let oFlag = mode.rawValue | options.rawValue

    return SyscallUtilities.valueOrErrno {
      if let permissions {
        return SystemLibc.openat(base.toFD, path, oFlag, permissions.rawValue)
      }
      precondition(!options.contains(.create),
                   "Create must be given permissions")
      return SystemLibc.openat(base.toFD, path, oFlag)
    }.map(FileDescriptor.init)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func close(_ fd: Int32) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.close(fd)
    }
  }
}

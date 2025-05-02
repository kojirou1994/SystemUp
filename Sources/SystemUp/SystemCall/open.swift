import SystemPackage
import SystemLibc

public extension SystemCall {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func open(_ path: UnsafePointer<CChar>, relativeTo base: RelativeDirectory = .cwd, _ mode: FileDescriptor.AccessMode,
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
}

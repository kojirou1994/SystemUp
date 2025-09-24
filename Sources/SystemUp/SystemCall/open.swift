import SystemPackage
import CUtility
import SystemLibc

public extension SystemCall {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func open(_ path: borrowing some CString, relativeTo base: RelativeDirectory = .cwd, _ mode: FileDescriptor.AccessMode,
                   options: FileDescriptor.OpenOptions = .init(),
                   permissions: FilePermissions? = nil) throws(Errno) -> FileDescriptor {

    let oFlag = mode.rawValue | options.rawValue

    return try SyscallUtilities.valueOrErrno {
      path.withUnsafeCString { path in
        if let permissions {
          return SystemLibc.openat(base.toFD, path, oFlag, permissions.rawValue)
        }
        precondition(!options.contains(.create),
                     "Create must be given permissions")
        return SystemLibc.openat(base.toFD, path, oFlag)
      }
    }.map(FileDescriptor.init).get()
  }
}

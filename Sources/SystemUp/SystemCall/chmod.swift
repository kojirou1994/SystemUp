import SystemPackage
import CUtility
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(permissions: FilePermissions, for path: borrowing some CString, relativeTo base: RelativeDirectory = .cwd, flags: AtFlags = []) throws(Errno) {
    assert(flags.isSubset(of: [.noFollow]))
    try SyscallUtilities.voidOrErrno {
      path.withUnsafeCString { path in
        SystemLibc.fchmodat(base.toFD, path, permissions.rawValue, flags.rawValue)
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(permissions: FilePermissions, for fd: FileDescriptor) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.fchmod(fd.rawValue, permissions.rawValue)
    }.get()
  }
}

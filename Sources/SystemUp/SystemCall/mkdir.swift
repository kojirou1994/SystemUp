import SystemPackage
import SystemLibc
import CUtility

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createDirectory(_ path: borrowing some CString, relativeTo base: RelativeDirectory = .cwd, permissions: FilePermissions = .directoryDefault) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      path.withUnsafeCString { path in
        SystemLibc.mkdirat(base.toFD, path, permissions.rawValue)
      }
    }.get()
  }
}

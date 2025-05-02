import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createDirectory(_ path: UnsafePointer<CChar>, relativeTo base: RelativeDirectory = .cwd, permissions: FilePermissions = .directoryDefault) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.mkdirat(base.toFD, path, permissions.rawValue)
    }.get()
  }
}

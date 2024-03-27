import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {
  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createDirectory(_ path: String, relativeTo base: RelativeDirectory = .cwd, permissions: FilePermissions = .directoryDefault) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.mkdirat(base.toFD, path, permissions.rawValue)
    }
  }
}

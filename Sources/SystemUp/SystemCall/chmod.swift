import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(permissions: FilePermissions, for path: UnsafePointer<CChar>, relativeTo base: RelativeDirectory = .cwd, flags: AtFlags = []) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.noFollow]))
    return SyscallUtilities.voidOrErrno {
      fchmodat(base.toFD, path, permissions.rawValue, flags.rawValue)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(permissions: FilePermissions, for fd: FileDescriptor) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      fchmod(fd.rawValue, permissions.rawValue)
    }
  }
}

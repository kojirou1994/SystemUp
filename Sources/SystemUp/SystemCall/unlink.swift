import SystemPackage
import SystemLibc

public extension SystemCall {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func unlink(_ path: UnsafePointer<CChar>, relativeTo base: RelativeDirectory = .cwd, flags: AtFlags = []) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.removeDir]))
    return SyscallUtilities.voidOrErrno {
      SystemLibc.unlinkat(base.toFD, path, flags.rawValue)
    }
  }
}

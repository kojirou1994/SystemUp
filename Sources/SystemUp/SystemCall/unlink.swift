import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {
  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func unlink(_ path: String, relativeTo base: RelativeDirectory = .cwd, flags: AtFlags = []) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.removeDir]))
    return SyscallUtilities.voidOrErrno {
      SystemLibc.unlinkat(base.toFD, path, flags.rawValue)
    }
  }
}

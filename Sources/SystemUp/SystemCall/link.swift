import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {
  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createHardLink(_ linkPath: String, relativeTo linkBase: RelativeDirectory = .cwd, toDestination destPath: String, relativeTo dstBase: RelativeDirectory = .cwd, flags: FileSyscalls.AtFlags = []) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.follow]))
    return SyscallUtilities.voidOrErrno {
      linkat(dstBase.toFD, destPath, linkBase.toFD, linkPath, flags.rawValue)
    }
  }
}

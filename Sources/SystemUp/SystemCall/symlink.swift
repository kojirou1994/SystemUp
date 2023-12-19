import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {
  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createSymbolicLink(_ linkPath: String, relativeTo base: RelativeDirectory = .cwd, toDestination destPath: String) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      symlinkat(destPath, base.toFD, linkPath)
    }
  }
}

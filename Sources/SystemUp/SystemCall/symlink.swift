import SystemPackage
import SystemLibc

public extension SystemCall {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createSymbolicLink(_ linkPath: UnsafePointer<CChar>, relativeTo base: RelativeDirectory = .cwd, toDestination destPath: UnsafePointer<CChar>) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      symlinkat(destPath, base.toFD, linkPath)
    }
  }
}

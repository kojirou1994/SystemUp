import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createHardLink(_ linkPath: UnsafePointer<CChar>, relativeTo linkBase: RelativeDirectory = .cwd, toDestination destPath: UnsafePointer<CChar>, relativeTo dstBase: RelativeDirectory = .cwd, flags: AtFlags = []) throws(Errno) {
    assert(flags.isSubset(of: [.follow]))
    try SyscallUtilities.voidOrErrno {
      linkat(dstBase.toFD, destPath, linkBase.toFD, linkPath, flags.rawValue)
    }.get()
  }
}

import SystemLibc
import CUtility

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createHardLink(_ linkPath: borrowing some CString, relativeTo linkBase: RelativeDirectory = .cwd, toDestination destPath: borrowing some CString, relativeTo dstBase: RelativeDirectory = .cwd, flags: AtFlags = []) throws(Errno) {
    assert(flags.isSubset(of: [.follow]))
    try SyscallUtilities.voidOrErrno {
      linkPath.withUnsafeCString { linkPath in
        destPath.withUnsafeCString { destPath in
          linkat(dstBase.toFD, destPath, linkBase.toFD, linkPath, flags.rawValue)
        }
      }
    }.get()
  }
}

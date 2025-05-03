import SystemPackage
import SystemLibc
import CUtility

public extension SystemCall {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createSymbolicLink(_ linkPath: borrowing some CStringConvertible & ~Copyable, relativeTo base: RelativeDirectory = .cwd, toDestination destPath: borrowing some CStringConvertible & ~Copyable) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      linkPath.withUnsafeCString { linkPath in
        destPath.withUnsafeCString { destPath in
          symlinkat(destPath, base.toFD, linkPath)
        }
      }
    }.get()
  }
}

import SystemPackage
import SystemLibc
import CUtility

public extension SystemCall {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func unlink(_ path: some CStringConvertible, relativeTo base: RelativeDirectory = .cwd, flags: AtFlags = []) throws(Errno) {
    #if Xcode
    assert(flags.isSubset(of: [.removeDir, .noFollowAny]))
    #endif
    try SyscallUtilities.voidOrErrno {
      path.withUnsafeCString { path in
        SystemLibc.unlinkat(base.toFD, path, flags.rawValue)
      }
    }.get()
  }
}

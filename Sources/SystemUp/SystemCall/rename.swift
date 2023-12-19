import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {

  /// The rename() system call causes the link named old to be renamed as new.  If new exists, it is first removed.  Both old and new must be of the same type (that is, both must be either directories or non-directories) and must reside on the same file system.
  /// - Parameters:
  ///   - path: src path
  ///   - fd: src path relative opened directory fd
  ///   - newPath: dst path
  ///   - tofd: dst path relative opened directory fd
  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func rename(_ src: String, relativeTo srcBase: RelativeDirectory = .cwd, toDestination destPath: String, relativeTo dstBase: RelativeDirectory = .cwd) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      renameat(srcBase.toFD, src, dstBase.toFD, destPath)
    }
  }

  @CStringGeneric()
  @available(macOS 10.12, *)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func rename(_ src: String, relativeTo srcBase: RelativeDirectory = .cwd, toDestination destPath: String, relativeTo dstBase: RelativeDirectory = .cwd, flags: FileSyscalls.RenameFlags) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno { () -> Int32 in
#if canImport(Darwin)
      renameatx_np(srcBase.toFD, src, dstBase.toFD, destPath, flags.rawValue)
#elseif os(Linux)
      renameat2(srcBase.toFD, src, dstBase.toFD, destPath, flags.rawValue)
#endif
    }
  }
}

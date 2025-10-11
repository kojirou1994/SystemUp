#if canImport(Darwin)
import SystemLibc
import SystemPackage
import CUtility

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
public extension SystemCall {

  /// create copy on write clones of files
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func cloneFile(_ src: borrowing some CString, relativeTo srcBase: RelativeDirectory = .cwd, toDestination destPath: borrowing some CString, relativeTo dstBase: RelativeDirectory = .cwd, flags: CloneFlags = []) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      src.withUnsafeCString { src in
        destPath.withUnsafeCString { destPath in
          SystemLibc.clonefileat(
            srcBase.toFD, src,
            dstBase.toFD, destPath,
            flags.rawValue
          )
        }
      }
    }.get()
  }

  /// create copy on write clones of files
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func cloneFile(_ fd: FileDescriptor, toDestination destPath: borrowing some CString, relativeTo dstBase: RelativeDirectory = .cwd, flags: CloneFlags = []) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      destPath.withUnsafeCString { destPath in
        SystemLibc.fclonefileat(
          fd.rawValue,
          dstBase.toFD, destPath,
          flags.rawValue
        )
      }
    }.get()
  }

  struct CloneFlags: OptionSet, MacroRawRepresentable {
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }
    public let rawValue: UInt32

    /// Don't follow symbolic links
    @_alwaysEmitIntoClient
    public static var noFollow: Self { .init(macroValue: SystemLibc.CLONE_NOFOLLOW) }

    /// Don't copy ownership information from source
    @_alwaysEmitIntoClient
    public static var noOwnerCopy: Self { .init(macroValue: SystemLibc.CLONE_NOOWNERCOPY) }

    /// Copy access control lists from source
    @_alwaysEmitIntoClient
    public static var acl: Self { .init(macroValue: SystemLibc.CLONE_ACL) }
  }
}

#endif // Darwin platform

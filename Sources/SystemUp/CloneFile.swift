#if canImport(Darwin)
import SystemLibc
import SystemPackage
import CUtility

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
public extension FileSyscalls {

  /// create copy on write clones of files
  static func cloneFile(from src: FilePathOption, to dst: FilePathOption, flags: CloneFlags = []) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      src.path.withPlatformString { srcPath in
        dst.path.withPlatformString { dstPath in
          SystemLibc.clonefileat(
            src.relativedDirFD.rawValue, srcPath,
            dst.relativedDirFD.rawValue, dstPath,
            flags.rawValue
          )
        }
      }
    }
  }

  /// create copy on write clones of files
  static func cloneFile(from fd: FileDescriptor, to dst: FilePathOption, flags: CloneFlags = []) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      dst.path.withPlatformString { dstPath in
        SystemLibc.fclonefileat(
          fd.rawValue,
          dst.relativedDirFD.rawValue, dstPath,
          flags.rawValue
        )
      }
    }
  }

  struct CloneFlags: OptionSet, MacroRawRepresentable {
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

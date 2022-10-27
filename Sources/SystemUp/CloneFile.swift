#if canImport(Darwin)
import SystemLibc
import SystemPackage
import CUtility

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
public extension FileSyscalls {

  /// create copy on write clones of files
  @_alwaysEmitIntoClient
  static func cloneFile(from src: FilePathOption, to dst: FilePathOption, flags: CloneFlags = []) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      src.path.withPlatformString { srcPath in
        dst.path.withPlatformString { dstPath in
          clonefileat(
            src.relativedDirFD.rawValue, srcPath,
            dst.relativedDirFD.rawValue, dstPath,
            flags.rawValue
          )
        }
      }
    }
  }

  /// create copy on write clones of files
  @_alwaysEmitIntoClient
  static func cloneFile(from fd: FileDescriptor, to dst: FilePathOption, flags: CloneFlags = []) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      dst.path.withPlatformString { dstPath in
        fclonefileat(
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

    /// Don't follow the src file if it is a symbolic link (applicable only if the source is not a directory).  The symbolic link is itself cloned if src names a symbolic link.
    @_alwaysEmitIntoClient
    public static var noFollow: Self { .init(macroValue: CLONE_NOFOLLOW) }

    /// Don't copy ownership information from the source when run called with superuser privileges.  The symbolic link is itself cloned if src names a symbolic link.
    @_alwaysEmitIntoClient
    public static var noOwnerCopy: Self { .init(macroValue: CLONE_NOOWNERCOPY) }

  }
  
}

#endif // Darwin platform

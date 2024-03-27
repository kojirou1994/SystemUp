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
  static func rename(_ src: String, relativeTo srcBase: RelativeDirectory = .cwd, toDestination destPath: String, relativeTo dstBase: RelativeDirectory = .cwd, flags: RenameFlags) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno { () -> Int32 in
#if canImport(Darwin)
      renameatx_np(srcBase.toFD, src, dstBase.toFD, destPath, flags.rawValue)
#elseif os(Linux)
      renameat2(srcBase.toFD, src, dstBase.toFD, destPath, flags.rawValue)
#endif
    }
  }

  struct RenameFlags: OptionSet, MacroRawRepresentable {

    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    public let rawValue: UInt32

    /// On file systems that support it (see getattrlist(2) VOL_CAP_INT_RENAME_SWAP), it will cause the source and target to be atomically swapped.  Source and target need not be of the same type, i.e. it is possible to swap a file with a directory.  EINVAL is returned in case of bitwise-inclusive OR with RENAME_EXCL.
    @_alwaysEmitIntoClient
    public static var swap: Self {
      #if canImport(Darwin)
      return .init(macroValue: RENAME_SWAP)
      #else
      return .init(macroValue: 1 << 1)
      #endif
    }

    @available(*, unavailable, renamed: "swap")
    @_alwaysEmitIntoClient
    public static var exchange: Self { .swap }

    /// On file systems that support it (see getattrlist(2) VOL_CAP_INT_RENAME_EXCL), it will cause EEXIST to be returned if the destination already exists. EINVAL is returned in case of bitwise-inclusive OR with RENAME_SWAP.
    @_alwaysEmitIntoClient
    public static var exclusive: Self {
      #if canImport(Darwin)
      return .init(macroValue: RENAME_EXCL)
      #else
      return .init(macroValue: 1 << 0)
      #endif
    }

    @available(*, unavailable, renamed: "exclisive")
    @_alwaysEmitIntoClient
    public static var noReplace: Self { .exclusive }

    /// If any symbolic links are encountered during pathname resolution, an error is returned.
    #if canImport(Darwin)
    @_alwaysEmitIntoClient
    public static var noFollowAny: Self {
      .init(macroValue: RENAME_NOFOLLOW_ANY)
    }
    #endif

    #if os(Linux)
    @_alwaysEmitIntoClient
    public static var whiteOut: Self {
      .init(macroValue: 1 << 2)
    }
    #endif
  }
}

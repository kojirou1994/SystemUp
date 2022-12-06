import SystemPackage
import SystemLibc
import Foundation
import SyscallValue
import CUtility

public enum FileSyscalls {}

public extension FileSyscalls {

  static func createDirectory(_ option: FilePathOption, permissions: FilePermissions = .directoryDefault) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      option.path.withPlatformString { path in
        mkdirat(option.relativedDirFD.rawValue, path, permissions.rawValue)
      }
    }
  }

  static func unlink(_ option: FilePathOption, flags: AtFlags = []) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.removeDir]))
    return SyscallUtilities.voidOrErrno {
      option.path.withPlatformString { path in
        unlinkat(option.relativedDirFD.rawValue, path, flags.rawValue)
      }
    }
  }

  static func fileStatus(_ fd: FileDescriptor, into status: inout FileStatus) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      fstat(fd.rawValue, &status.rawValue)
    }
  }

  static func fileStatus(_ option: FilePathOption, flags: AtFlags = [], into status: inout FileStatus) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.noFollow]))
    return SyscallUtilities.voidOrErrno {
      option.path.withPlatformString { path in
        fstatat(option.relativedDirFD.rawValue, path, &status.rawValue, flags.rawValue)
      }
    }
  }

  static func fileSystemStatistics(_ fd: FileDescriptor, into s: inout FileSystemStatistics) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      fstatfs(fd.rawValue, &s.rawValue)
    }
  }

  static func fileSystemStatistics(_ path: FilePath, into s: inout FileSystemStatistics) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      path.withPlatformString { path in
        statfs(path, &s.rawValue)
      }
    }
  }

  static func fileSystemInformation(_ fd: FileDescriptor, into s: inout FileSystemInformation) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      fstatvfs(fd.rawValue, &s.rawValue)
    }
  }

  static func fileSystemInformation(_ path: FilePath, into s: inout FileSystemInformation) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      path.withPlatformString { path in
        statvfs(path, &s.rawValue)
      }
    }
  }
}

// MARK: symbolic link
public extension FileSyscalls {

  static func createSymbolicLink(_ option: FilePathOption, toDestination dest: FilePath) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      option.path.withPlatformString { path in
        dest.withPlatformString { dest in
          symlinkat(dest, option.relativedDirFD.rawValue, path)
        }
      }
    }
  }

  static func readLink(_ option: FilePathOption) throws -> String {
    let count = Int(PATH_MAX) + 1
    return try .init(capacity: count) { ptr in
      try option.path.withPlatformString { path in
        let newCount = readlinkat(option.relativedDirFD.rawValue, path, ptr, count)
        if newCount == -1 {
          throw Errno.systemCurrent
        }
        return newCount
      }
    }
  }

  static func realPath(_ path: FilePath) throws -> FilePath {
    try .init(String(capacity: Int(PATH_MAX) + 1, { buffer in
      try path.withPlatformString { path in
        let cstr = buffer.assumingMemoryBound(to: CChar.self)
        let ptr = realpath(path, cstr)
        if ptr == nil {
          throw Errno.systemCurrent
        }
        assert(ptr == cstr)
        return strlen(cstr)
      }
    }))
  }
}

// MARK: chmod
public extension FileSyscalls {

  static func set(_ option: FilePathOption, permissions: FilePermissions, flags: AtFlags = []) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.noFollow]))
    return SyscallUtilities.voidOrErrno {
      option.path.withPlatformString { path in
        fchmodat(option.relativedDirFD.rawValue, path, permissions.rawValue, flags.rawValue)
      }
    }
  }

  static func set(_ fd: FileDescriptor, permissions: FilePermissions) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      fchmod(fd.rawValue, permissions.rawValue)
    }
  }

}

// MARK: chflags
#if canImport(Darwin)
public extension FileSyscalls {

  struct FileFlags: OptionSet, MacroRawRepresentable {

    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    public let rawValue: UInt32

    /// Do not dump the file.
    @_alwaysEmitIntoClient
    public static var userNoDump: Self { .init(macroValue: UF_NODUMP) }

    /// The file may not be changed.
    @_alwaysEmitIntoClient
    public static var userImmutable: Self { .init(macroValue: UF_IMMUTABLE) }

    /// The file may only be appended to.
    @_alwaysEmitIntoClient
    public static var userAppend: Self { .init(macroValue: UF_APPEND) }

    /// The directory is opaque when viewed through a union stack.
    @_alwaysEmitIntoClient
    public static var userOpaque: Self { .init(macroValue: UF_OPAQUE) }

    /// The file or directory is not intended to be displayed to the user.
    @_alwaysEmitIntoClient
    public static var userHidden: Self { .init(macroValue: UF_HIDDEN) }

    /// The file has been archived.
    @_alwaysEmitIntoClient
    public static var superArchived: Self { .init(macroValue: SF_ARCHIVED) }

    /// The file may not be changed.
    @_alwaysEmitIntoClient
    public static var superImmutable: Self { .init(macroValue: SF_IMMUTABLE) }

    /// The file may only be appended to.
    @_alwaysEmitIntoClient
    public static var superAppend: Self { .init(macroValue: SF_APPEND) }

    /// The file is a dataless placeholder.  The system will attempt to materialize it when accessed according to the dataless file materialization policy of the accessing thread or process.  See getiopolicy_np(3).
    @_alwaysEmitIntoClient
    public static var superDataless: Self { .init(macroValue: SF_DATALESS) }

  }

  static func set(_ path: FilePath, flags: FileFlags) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      path.withPlatformString { path in
        chflags(path, flags.rawValue)
      }
    }
  }

  static func set(_ fd: FileDescriptor, flags: FileFlags) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      fchflags(fd.rawValue, flags.rawValue)
    }
  }
}
#endif // chflags end

// MARK: truncate
public extension FileSyscalls {

  static func truncate(_ path: FilePath, size: Int) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      path.withPlatformString { path in
        SystemLibc.truncate(path, off_t(size))
      }
    }
  }

  static func truncate(_ fd: FileDescriptor, size: Int) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.ftruncate(fd.rawValue, off_t(size))
    }
  }

}

// MARK: access
public extension FileSyscalls {

  struct Accessibility: OptionSet, MacroRawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// test for existence of file
    @_alwaysEmitIntoClient
    public static var existence: Self { .init(macroValue: F_OK) }

    /// test for execute or search permission
    @_alwaysEmitIntoClient
    public static var execute: Self { .init(macroValue: X_OK) }

    /// test for write permission
    @_alwaysEmitIntoClient
    public static var write: Self { .init(macroValue: W_OK) }

    @_alwaysEmitIntoClient
    public static var read: Self { .init(macroValue: R_OK) }

  }

  static func check(_ option: FilePathOption, accessibility: Accessibility, flags: AtFlags = []) -> Bool {
    assert(!option.path.isEmpty)
    assert(flags.isSubset(of: [.noFollow, .effectiveAccess]))
    return option.path.withPlatformString { path in
      SystemLibc.faccessat(option.relativedDirFD.rawValue, path, accessibility.rawValue, flags.rawValue) == 0
    }
  }

}

public extension FileSyscalls {
  struct AtFlags: OptionSet, MacroRawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// Use effective ids in access check
    @_alwaysEmitIntoClient
    public static var effectiveAccess: Self { .init(macroValue: AT_EACCESS) }

    /// Act on the symlink itself not the target
    @_alwaysEmitIntoClient
    public static var noFollow: Self { .init(macroValue: AT_SYMLINK_NOFOLLOW) }

    /// Act on target of symlink
    @_alwaysEmitIntoClient
    public static var follow: Self { .init(macroValue: AT_SYMLINK_FOLLOW) }

    /// Path refers to directory
    @_alwaysEmitIntoClient
    public static var removeDir: Self { .init(macroValue: AT_REMOVEDIR) }

    /// Return real device inodes resides on for fstatat(2)
    #if canImport(Darwin)
    @_alwaysEmitIntoClient
    public static var realDevice: Self { .init(macroValue: AT_REALDEV) }
    #endif

    /// Use only the fd and Ignore the path for fstatat(2)
    #if canImport(Darwin)
    @_alwaysEmitIntoClient
    public static var fdOnly: Self { .init(macroValue: AT_FDONLY) }
    #endif
  }

}

// MARK: rename
public extension FileSyscalls {

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

  /// The rename() system call causes the link named old to be renamed as new.  If new exists, it is first removed.  Both old and new must be of the same type (that is, both must be either directories or non-directories) and must reside on the same file system.
  /// - Parameters:
  ///   - path: src path
  ///   - fd: src path relative opened directory fd
  ///   - newPath: dst path
  ///   - tofd: dst path relative opened directory fd
  static func rename(_ src: FilePathOption, to dst: FilePathOption) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      src.path.withPlatformString { old in
        dst.path.withPlatformString { new in
          renameat(src.relativedDirFD.rawValue, old, dst.relativedDirFD.rawValue, new)
        }
      }
    }
  }

  #if canImport(Darwin)
  @available(macOS 10.12, *)
  static func rename(_ src: FilePathOption, to dst: FilePathOption, flags: RenameFlags) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      src.path.withPlatformString { old in
        dst.path.withPlatformString { new -> Int32 in
          renameatx_np(src.relativedDirFD.rawValue, old, dst.relativedDirFD.rawValue, new, flags.rawValue)
        }
      }
    }
  }
  #endif
}

// MARK: working directory
public extension FileSyscalls {

  static func getWorkingDirectory() -> Result<FilePath, Errno> {
    SyscallUtilities.unwrap {
      SystemLibc.getcwd(nil, 0)
    }.map { path in
      defer {
        path.deallocate()
      }
      return .init(platformString: path)
    }
  }

  static func changeWorkingDirectory(_ path: FilePath) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      path.withPlatformString { path in
        SystemLibc.chdir(path)
      }
    }
  }

  static func changeWorkingDirectory(_ fd: FileDescriptor) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.fchdir(fd.rawValue)
    }
  }
}

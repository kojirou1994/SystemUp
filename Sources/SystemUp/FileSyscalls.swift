import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
import CSystemUp
#endif
import Foundation
import SyscallValue
import CUtility

public enum FileSyscalls {}

public extension FileSyscalls {

  static func createDirectory(_ option: FilePathOption, permissions: FilePermissions = .directoryDefault) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      option.path.withPlatformString { path in
        mkdirat(option.relativedDirFD.rawValue, path, permissions.rawValue)
      }
    }
  }

  static func unlink(_ option: FilePathOption, flags: AtFlags = []) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.removeDir]))
    return nothingOrErrno(retryOnInterrupt: false) {
      option.path.withPlatformString { path in
        unlinkat(option.relativedDirFD.rawValue, path, flags.rawValue)
      }
    }
  }

  static func fileStatus(_ fd: FileDescriptor) -> Result<FileStatus, Errno> {
    var s = FileStatus()
    return fileStatus(fd, into: &s).map { s }
  }

  static func fileStatus(_ fd: FileDescriptor, into status: inout FileStatus) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      fstat(fd.rawValue, &status.status)
    }
  }

  static func fileStatus(_ option: FilePathOption, flags: AtFlags = []) -> Result<FileStatus, Errno> {
    var s = FileStatus()
    return fileStatus(option, flags: flags, into: &s).map { s }
  }

  static func fileStatus(_ option: FilePathOption, flags: AtFlags = [], into status: inout FileStatus) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.noFollow]))
    return nothingOrErrno(retryOnInterrupt: false) {
      option.path.withPlatformString { path in
        fstatat(option.relativedDirFD.rawValue, path, &status.status, flags.rawValue)
      }
    }
  }
}

// MARK: symbolic link
public extension FileSyscalls {

  static func createSymbolicLink(_ option: FilePathOption, toDestination dest: FilePath) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
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
        let newCount = readlinkat(option.relativedDirFD.rawValue, path, ptr.assumingMemoryBound(to: CChar.self), count)
        if newCount == -1 {
          throw Errno.current
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
          throw Errno.current
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
    return nothingOrErrno(retryOnInterrupt: false) {
      option.path.withPlatformString { path in
        fchmodat(option.relativedDirFD.rawValue, path, permissions.rawValue, flags.rawValue)
      }
    }
  }

  static func set(_ fd: FileDescriptor, permissions: FilePermissions) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      fchmod(fd.rawValue, permissions.rawValue)
    }
  }

}

// MARK: chflags
#if canImport(Darwin)
public extension FileSyscalls {

  struct FileFlags: OptionSet {

    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    public let rawValue: UInt32

    /// Do not dump the file.
    @_alwaysEmitIntoClient
    public static var userNoDump: Self { .init(UF_NODUMP) }

    /// The file may not be changed.
    @_alwaysEmitIntoClient
    public static var userImmutable: Self { .init(UF_IMMUTABLE) }

    /// The file may only be appended to.
    @_alwaysEmitIntoClient
    public static var userAppend: Self { .init(UF_APPEND) }

    /// The directory is opaque when viewed through a union stack.
    @_alwaysEmitIntoClient
    public static var userOpaque: Self { .init(UF_OPAQUE) }

    /// The file or directory is not intended to be displayed to the user.
    @_alwaysEmitIntoClient
    public static var userHidden: Self { .init(UF_HIDDEN) }

    /// The file has been archived.
    @_alwaysEmitIntoClient
    public static var superArchived: Self { .init(SF_ARCHIVED) }

    /// The file may not be changed.
    @_alwaysEmitIntoClient
    public static var superImmutable: Self { .init(SF_IMMUTABLE) }

    /// The file may only be appended to.
    @_alwaysEmitIntoClient
    public static var superAppend: Self { .init(SF_APPEND) }

    /// The file is a dataless placeholder.  The system will attempt to materialize it when accessed according to the dataless file materialization policy of the accessing thread or process.  See getiopolicy_np(3).
    @_alwaysEmitIntoClient
    public static var superDataless: Self { .init(SF_DATALESS) }

  }

  static func set(_ path: FilePath, flags: FileFlags) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        chflags(path, flags.rawValue)
      }
    }
  }

  static func set(_ fd: FileDescriptor, flags: FileFlags) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      fchflags(fd.rawValue, flags.rawValue)
    }
  }
}
#endif // chflags end

// MARK: truncate
public extension FileSyscalls {

  static func truncate(_ path: FilePath, size: Int) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        system_truncate(path, off_t(size))
      }
    }
  }

  static func truncate(_ fd: FileDescriptor, size: Int) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      system_ftruncate(fd.rawValue, off_t(size))
    }
  }

}

// MARK: access
public extension FileSyscalls {

  struct Accessibility: OptionSet {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// test for existence of file
    @_alwaysEmitIntoClient
    public static var existence: Self { .init(F_OK) }

    /// test for execute or search permission
    @_alwaysEmitIntoClient
    public static var execute: Self { .init(X_OK) }

    /// test for write permission
    @_alwaysEmitIntoClient
    public static var write: Self { .init(W_OK) }

  }

  static func check(_ option: FilePathOption, accessibility: Accessibility, flags: AtFlags = []) -> Bool {
    assert(!option.path.isEmpty)
    assert(flags.isSubset(of: [.noFollow, .effectiveAccess]))
    return option.path.withPlatformString { path in
      system_access(option.relativedDirFD.rawValue, path, accessibility.rawValue, flags.rawValue) == 0
    }
  }

}

public extension FileSyscalls {
  struct AtFlags: OptionSet {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// Use effective ids in access check
    @_alwaysEmitIntoClient
    public static var effectiveAccess: Self { .init(AT_EACCESS) }

    /// Act on the symlink itself not the target
    @_alwaysEmitIntoClient
    public static var noFollow: Self { .init(AT_SYMLINK_NOFOLLOW) }

    /// Act on target of symlink
    @_alwaysEmitIntoClient
    public static var follow: Self { .init(AT_SYMLINK_FOLLOW) }

    /// Path refers to directory
    @_alwaysEmitIntoClient
    public static var removeDir: Self { .init(AT_REMOVEDIR) }

    /// Return real device inodes resides on for fstatat(2)
    #if canImport(Darwin)
    @_alwaysEmitIntoClient
    public static var realDevice: Self { .init(AT_REALDEV) }
    #endif

    /// Use only the fd and Ignore the path for fstatat(2)
    #if canImport(Darwin)
    @_alwaysEmitIntoClient
    public static var fdOnly: Self { .init(AT_FDONLY) }
    #endif
  }

}

// MARK: rename
public extension FileSyscalls {

  struct RenameFlags: OptionSet {

    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    public let rawValue: UInt32

    /// On file systems that support it (see getattrlist(2) VOL_CAP_INT_RENAME_SWAP), it will cause the source and target to be atomically swapped.  Source and target need not be of the same type, i.e. it is possible to swap a file with a directory.  EINVAL is returned in case of bitwise-inclusive OR with RENAME_EXCL.
    @_alwaysEmitIntoClient
    public static var swap: Self {
      #if canImport(Darwin)
      return .init(RENAME_SWAP)
      #else
      return .init(rawValue: 1 << 1)
      #endif
    }

    @available(*, unavailable, renamed: "swap")
    @_alwaysEmitIntoClient
    public static var exchange: Self { .swap }

    /// On file systems that support it (see getattrlist(2) VOL_CAP_INT_RENAME_EXCL), it will cause EEXIST to be returned if the destination already exists. EINVAL is returned in case of bitwise-inclusive OR with RENAME_SWAP.
    @_alwaysEmitIntoClient
    public static var exclisive: Self {
      #if canImport(Darwin)
      return .init(RENAME_EXCL)
      #else
      return .init(rawValue: 1 << 0)
      #endif
    }

    @available(*, unavailable, renamed: "exclisive")
    @_alwaysEmitIntoClient
    public static var noReplace: Self { .exclisive }

    /// If any symbolic links are encountered during pathname resolution, an error is returned.
    #if canImport(Darwin)
    @_alwaysEmitIntoClient
    public static var noFollowAny: Self {
      .init(RENAME_NOFOLLOW_ANY)
    }
    #endif

    #if os(Linux)
    @_alwaysEmitIntoClient
    public static var whiteOut: Self {
      .init(rawValue: 1 << 2)
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
    nothingOrErrno(retryOnInterrupt: false) {
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
    nothingOrErrno(retryOnInterrupt: false) {
      src.path.withPlatformString { old in
        dst.path.withPlatformString { new -> Int32 in
          renameatx_np(src.relativedDirFD.rawValue, old, dst.relativedDirFD.rawValue, new, flags.rawValue)
        }
      }
    }
  }
  #endif
}

// MARK: cwd
public extension FileSyscalls {
  static var currentDirectoryPath: FilePath {
    let path = getcwd(nil, 0)!
    defer {
      free(path)
    }
    return .init(platformString: path)
  }

  static func changeCurrentDirectoryPath(_ path: FilePath) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        chdir(path)
      }
    }
  }

  static func changeCurrentDirectoryPath(_ fd: FileDescriptor) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      fchdir(fd.rawValue)
    }
  }
}

import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation
import SyscallValue
import KwiftC

public enum FileUtility {
}

public extension FileUtility {

  @_alwaysEmitIntoClient
  static func createDirectory(_ path: FilePath, relativeTo fd: FileDescriptor = .currentWorkingDirectory, permissions: FilePermissions = .directoryDefault) throws {
    assert(!path.isEmpty)
    try nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        mkdirat(fd.rawValue, path, permissions.rawValue)
      }
    }.get()
  }

  @_alwaysEmitIntoClient
  static func unlink(_ path: FilePath, relativeTo fd: FileDescriptor = .currentWorkingDirectory, flags: AtFlags = []) throws {
    assert(!path.isEmpty)
    assert(flags.isSubset(of: [.removeDir]))
    try nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        unlinkat(fd.rawValue, path, flags.rawValue)
      }
    }.get()
  }

  @_alwaysEmitIntoClient
  static func removeDirectory(_ path: FilePath, relativeTo fd: FileDescriptor = .currentWorkingDirectory) throws {
    try unlink(path, relativeTo: fd, flags: .removeDir)
  }

  @_alwaysEmitIntoClient
  static func fileStatus(_ fd: FileDescriptor) throws -> FileStatus {
    var s = FileStatus()
    try fileStatus(fd, into: &s)
    return s
  }

  @_alwaysEmitIntoClient
  static func fileStatus(_ fd: FileDescriptor, into status: inout FileStatus) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      fstat(fd.rawValue, &status.status)
    }.get()
  }

  @_alwaysEmitIntoClient
  static func fileStatus(_ path: FilePath, relativeTo fd: FileDescriptor = .currentWorkingDirectory, flags: AtFlags = []) throws -> FileStatus {
    var s = FileStatus()
    try fileStatus(path, relativeTo: fd, flags: flags, into: &s)
    return s
  }

  @_alwaysEmitIntoClient
  static func fileStatus(_ path: FilePath, relativeTo fd: FileDescriptor = .currentWorkingDirectory, flags: AtFlags = [], into status: inout FileStatus) throws {
    assert(!path.isEmpty)
    assert(flags.isSubset(of: [.noFollow]))
    try nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        fstatat(fd.rawValue, path, &status.status, flags.rawValue)
      }
    }.get()
  }
}

// MARK: symbolic link
public extension FileUtility {

  @_alwaysEmitIntoClient
  static func createSymbolicLink(_ path: FilePath, relativeTo fd: FileDescriptor = .currentWorkingDirectory, toDestination dest: FilePath) throws {
    assert(!path.isEmpty)
    //    assert(!dest.isEmpty)
    try nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        dest.withPlatformString { dest in
          symlinkat(dest, fd.rawValue, path)
        }
      }
    }.get()
  }

  @_alwaysEmitIntoClient
  static func readLink(_ path: FilePath, relativeTo fd: FileDescriptor = .currentWorkingDirectory) throws -> String {
    assert(!path.isEmpty)
    let count = Int(PATH_MAX) + 1
    return try .init(capacity: count) { ptr in
      try path.withPlatformString { path in
        let newCount = readlinkat(fd.rawValue, path, ptr.assumingMemoryBound(to: CChar.self), count)
        if newCount == -1 {
          throw Errno.current
        }
        return newCount
      }
    }
  }

  @_alwaysEmitIntoClient
  static func realPath(_ path: FilePath) throws -> FilePath {
    assert(!path.isEmpty)
    return try .init(String(capacity: Int(PATH_MAX) + 1, { buffer in
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
public extension FileUtility {

  @_alwaysEmitIntoClient
  static func set(_ path: FilePath, relativeTo fd: FileDescriptor = .currentWorkingDirectory, permissions: FilePermissions, flags: AtFlags = []) throws {
    assert(!path.isEmpty)
    assert(flags.isSubset(of: [.noFollow]))
    try nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        fchmodat(fd.rawValue, path, permissions.rawValue, flags.rawValue)
      }
    }.get()
  }

  @_alwaysEmitIntoClient
  static func set(_ fd: FileDescriptor, permissions: FilePermissions) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      fchmod(fd.rawValue, permissions.rawValue)
    }.get()
  }

}

// MARK: chflags
public extension FileUtility {

  struct FileFlags: OptionSet {

    @_alwaysEmitIntoClient
    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    internal init(_ rawValue: Int32) {
      self.rawValue = .init(rawValue)
    }

    @_alwaysEmitIntoClient
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

  @_alwaysEmitIntoClient
  static func set(_ path: FilePath, flags: FileFlags) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        chflags(path, flags.rawValue)
      }
    }.get()
  }

  @_alwaysEmitIntoClient
  static func set(_ fd: FileDescriptor, flags: FileFlags) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      fchflags(fd.rawValue, flags.rawValue)
    }.get()
  }
}

// MARK: truncate
public extension FileUtility {

  @_alwaysEmitIntoClient
  static func truncate(_ path: FilePath, size: Int) throws {
    assert(!path.isEmpty)
    try nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        system_truncate(path, off_t(size))
      }
    }.get()
  }

  @_alwaysEmitIntoClient
  static func truncate(_ fd: FileDescriptor, size: Int) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      system_ftruncate(fd.rawValue, off_t(size))
    }.get()
  }

}

// MARK: access
public extension FileUtility {

  struct Accessibility: OptionSet {

    @_alwaysEmitIntoClient
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    internal init(_ rawValue: Int32) {
      self.rawValue = .init(rawValue)
    }

    @_alwaysEmitIntoClient
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

  @_alwaysEmitIntoClient
  static func check(_ path: FilePath, relativeTo fd: FileDescriptor = .currentWorkingDirectory, accessibility: Accessibility, flags: AtFlags = []) -> Bool {
    assert(!path.isEmpty)
    assert(flags.isSubset(of: [.noFollow, .effectiveAccess]))
    return path.withPlatformString { path in
      system_access(fd.rawValue, path, accessibility.rawValue, flags.rawValue) == 0
    }
  }

}

public extension FileUtility {
  struct AtFlags: OptionSet {

    @_alwaysEmitIntoClient
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    internal init(_ rawValue: Int32) {
      self.rawValue = .init(rawValue)
    }

    @_alwaysEmitIntoClient
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
    @_alwaysEmitIntoClient
    public static var realDevice: Self { .init(AT_REALDEV) }

    /// Use only the fd and Ignore the path for fstatat(2)
    @_alwaysEmitIntoClient
    public static var fdOnly: Self { .init(AT_FDONLY) }
  }

}

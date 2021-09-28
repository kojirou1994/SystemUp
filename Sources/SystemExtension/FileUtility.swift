import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation
import SyscallValue
import KwiftC

public struct FileUtility {

  @_alwaysEmitIntoClient
  public static func createDirectory(_ path: FilePath, permissions: FilePermissions = .directoryDefault) throws {
#if DEBUG && Xcode
    print(#function, path)
#endif
    assert(!path.isEmpty)
    try valueOrErrno(
      path.withPlatformString { str in
        mkdir(str, permissions.rawValue)
      }
    )
  }

  @_alwaysEmitIntoClient
  public static func createDirectoryIntermediately(_ path: FilePath) throws {
    do {
      let fileStat = try fileStatus(path, resolveSymbolicLink: true)
      if fileStat.fileType == .directory {
        return
      } else {
        throw Errno.fileExists
      }
    } catch Errno.noSuchFileOrDirectory {
      // create parent
      var parent = path
      if parent.removeLastComponent(), !parent.isEmpty {
        try createDirectoryIntermediately(parent)
      }
    }
    try createDirectory(path, permissions: [.ownerReadWriteExecute, .groupReadWriteExecute, .otherReadWriteExecute])
  }

  @_alwaysEmitIntoClient
  public static func remove(_ path: FilePath) throws {
#if DEBUG && Xcode
    print(#function, self)
#endif
    assert(!path.isEmpty)
    let s = try fileStatus(path, resolveSymbolicLink: false)
    if s.fileType == .directory {
      try removeDirectoryRecursive(path)
    } else {
      try unlinkFile(path)
    }
  }

  @_alwaysEmitIntoClient
  public static func unlinkFile(_ path: FilePath) throws {
#if DEBUG && Xcode
    print(#function, self)
#endif
    assert(!path.isEmpty)
    try valueOrErrno(
      path.withPlatformString { str in
        unlink(str)
      }
    )
  }

  @_alwaysEmitIntoClient
  public static func removeDirectory(_ path: FilePath) throws {
#if DEBUG && Xcode
    print(#function, self)
#endif
    assert(!path.isEmpty)
    try valueOrErrno(
      path.withPlatformString { str in
        rmdir(str)
      }
    )
  }

  @_alwaysEmitIntoClient
  public static func removeDirectoryRecursive(_ path: FilePath) throws {
#if DEBUG && Xcode
    print(#function, self)
#endif
    try Directory.open(path)
      .closeAfter { directory in
        var entry = Directory.Entry()
        while try directory.read(into: &entry) {
          if entry.isInvalid {
            continue
          }
          let entryName = entry.name
          let childPath = path.appending(entryName)
          switch entry.fileType {
          case .directory: try removeDirectoryRecursive(childPath)
          default: try unlinkFile(childPath)
          }
        }
      } // Directory open
    try removeDirectory(path)
  }

  @_alwaysEmitIntoClient
  public static func fileStatus(_ fd: FileDescriptor) throws -> FileStatus {
    var s = stat()
    try valueOrErrno(
      fstat(fd.rawValue, &s)
    )
    return .init(s)
  }

  @_alwaysEmitIntoClient
  public static func fileStatus(_ path: FilePath, resolveSymbolicLink: Bool) throws -> FileStatus {
    assert(!path.isEmpty)
    var s = stat()
    try valueOrErrno(
      path.withPlatformString { path -> Int32 in
        if resolveSymbolicLink {
          return stat(path, &s)
        } else {
          return lstat(path, &s)
        }
      })
    return .init(s)
  }
}

extension FileUtility {

  @_alwaysEmitIntoClient
  public static func symLink(_ path: FilePath, to dest: String) throws {
    assert(!path.isEmpty)
    try valueOrErrno(
      path.withPlatformString { path in
        symlink(dest, path)
      }
    )
  }

  @_alwaysEmitIntoClient
  public static func symLink(_ path: FilePath, to dest: FilePath) throws {
    assert(!path.isEmpty)
    try valueOrErrno(
      path.withPlatformString { path in
        dest.withPlatformString { dest in
          symlink(dest, path)
        }
      }
    )
  }

  @_alwaysEmitIntoClient
  public static func readLink(_ path: FilePath) throws -> String {
    assert(!path.isEmpty)
    let count = Int(PATH_MAX) + 1
    return try .init(capacity: count) { ptr in
      try path.withPlatformString { path in
        let newCount = readlink(path, ptr.assumingMemoryBound(to: CChar.self), count)
        if newCount == -1 {
          throw Errno.current
        }
        return newCount
      }
    }
  }

  @_alwaysEmitIntoClient
  public static func realPath(_ path: FilePath) throws -> FilePath {
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

extension FileUtility {

  @_alwaysEmitIntoClient
  public static func changeMode(_ path: FilePath, permissions: FilePermissions) throws {
    assert(!path.isEmpty)
    try valueOrErrno(
      path.withPlatformString { path in
        chmod(path, permissions.rawValue)
      }
    )
  }

  @_alwaysEmitIntoClient
  public static func changeMode(_ fd: FileDescriptor, permissions: FilePermissions) throws {
    try valueOrErrno(
      fchmod(fd.rawValue, permissions.rawValue)
    )
  }

  public typealias FileFlags = UInt32

  @_alwaysEmitIntoClient
  public static func changeFlags(_ path: FilePath, flags: FileFlags) throws {
    try valueOrErrno(
      path.withPlatformString { path in
        chflags(path, flags)
      }
    )
  }

  @_alwaysEmitIntoClient
  public static func changeFlags(_ fd: FileDescriptor, flags: FileFlags) throws {
    try valueOrErrno(
      fchflags(fd.rawValue, flags)
    )
  }
}

// MARK: truncate
extension FileUtility {

  @_alwaysEmitIntoClient
  public static func truncate(_ path: FilePath, size: Int) throws {
    assert(!path.isEmpty)
    try valueOrErrno(
      path.withPlatformString { path in
        _truncate(path, off_t(size))
      }
    )
  }

  @_alwaysEmitIntoClient
  public static func truncate(_ fd: FileDescriptor, size: Int) throws {
    try valueOrErrno(
      ftruncate(fd.rawValue, off_t(size))
    )
  }

}

@_alwaysEmitIntoClient
fileprivate let _truncate = truncate

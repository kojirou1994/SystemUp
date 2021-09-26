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
  public static func createDirectory(_ path: FilePath, permissions: FilePermissions = .directoryDefault) throws {
#if DEBUG && Xcode
    print(#function, path)
#endif
    try valueOrErrno(
      path.withPlatformString { str in
        mkdir(str, permissions.rawValue)
      }
    )
  }

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
      if parent.removeLastComponent() {
        try createDirectoryIntermediately(parent)
      }
    }
    try createDirectory(path, permissions: [.ownerReadWriteExecute, .groupReadWriteExecute, .otherReadWriteExecute])
  }

  public static func remove(_ path: FilePath) throws {
#if DEBUG && Xcode
    print(#function, self)
#endif
    let s = try fileStatus(path, resolveSymbolicLink: false)
    if s.fileType == .directory {
      try removeDirectoryRecursive(path)
    } else {
      try unlinkFile(path)
    }
  }


  public static func unlinkFile(_ path: FilePath) throws {
#if DEBUG && Xcode
    print(#function, self)
#endif
    try valueOrErrno(
      path.withPlatformString { str in
        unlink(str)
      }
    )
  }

  public static func removeDirectory(_ path: FilePath) throws {
#if DEBUG && Xcode
    print(#function, self)
#endif
    try valueOrErrno(
      path.withPlatformString { str in
        rmdir(str)
      }
    )
  }

  public static func removeDirectoryRecursive(_ path: FilePath) throws {
#if DEBUG && Xcode
    print(#function, self)
#endif
//    try Directory.withOpenedDirectory(path) { rootPath, directory in
//      var entry = Directory.Entry()
//      while try directory.read(into: &entry) {
//        let entryName = entry.name
//        if entryName == "." || entryName == ".." {
//          continue
//        }
//        let childItem = rootPath.appending(entryName)
//        switch try fileStatus(childItem, resolveSymbolicLink: false).fileType {
//        case .directory: try removeDirectoryRecursive(childItem)
//        default: try unlinkFile(childItem)
//        }
//      }
//    } // Directory open
    try removeDirectory(path)
  }

  public static func fileStatus(_ fd: FileDescriptor) throws -> FileStatus {
    var s = stat()
    try valueOrErrno(
      fstat(fd.rawValue, &s)
    )
    return .init(s)
  }

  @_alwaysEmitIntoClient
  public static func fileStatus(_ path: FilePath, resolveSymbolicLink: Bool) throws -> FileStatus {
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

  public static func symLink(_ path: FilePath, to dest: String) throws {
    try valueOrErrno(
      path.withPlatformString { path in
        symlink(dest, path)
      }
    )
  }

  public static func symLink(_ path: FilePath, to dest: FilePath) throws {
    try valueOrErrno(
      path.withPlatformString { path in
        dest.withPlatformString { dest in
          symlink(dest, path)
        }
      }
    )
  }

  public static func readLink(_ path: FilePath) throws -> String {
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

  public static func realPath(_ path: FilePath) throws -> FilePath {
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

extension FileUtility {

  public static func changeMode(_ path: FilePath, permissions: FilePermissions) throws {
    try valueOrErrno(
      path.withPlatformString { path in
        chmod(path, permissions.rawValue)
      }
    )
  }

  public static func changeMode(_ fd: FileDescriptor, permissions: FilePermissions) throws {
    try valueOrErrno(
      fchmod(fd.rawValue, permissions.rawValue)
    )
  }

  public typealias FileFlags = UInt32

  public static func changeFlags(_ path: FilePath, flags: FileFlags) throws {
    try valueOrErrno(
      path.withPlatformString { path in
        chflags(path, flags)
      }
    )
  }

  public static func changeFlags(_ fd: FileDescriptor, flags: FileFlags) throws {
    try valueOrErrno(
      fchflags(fd.rawValue, flags)
    )
  }
}

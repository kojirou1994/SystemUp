import SystemUp
import CUtility

public struct SystemFileManager {}

extension SystemFileManager {

  public static func createDirectoryIntermediately(_ path: borrowing some CString, relativeTo base: SystemCall.RelativeDirectory = .cwd, permissions: FilePermissions = .directoryDefault) throws(Errno) {
    // https://github.com/freebsd/freebsd-src/blob/main/bin/mkdir/mkdir.c
    try path.withCopiedMutable { path throws(Errno) in
      var statbuf: FileStatus = Memory.undefined()
      var current = path
      let sep = UInt8(ascii: "/")
      if current.pointee == sep { /* Skip leading '/'. */
        current += 1
      }
      var first = true
      var last = false
      while !last {
        defer {
          current += 1
        }
        if current.pointee == 0 {
          last = true
        } else if current.pointee != sep {
          continue
        }
        current.pointee = 0 // set sep to 0
        defer {
//          if !last {
          current.pointee = CChar(sep) // restore sep
//          }
        }
        if !last, current.successor().pointee == 0 { // ignore trailing '/'
          last = true
        }
        if first {
          // umask skiped
          first = false
        }
        if last {
          // umask skiped
        }

        do throws(Errno) {
          // try mkdir and check
          try SystemCall.createDirectory(path, relativeTo: base, permissions: permissions)
          if true { // verbose
            FileStream.write(string: path)
          }
        } catch {
//          Errno.print()
          switch error {
          case .fileExists, .isDirectory:
            do throws(Errno) {
              try SystemCall.fileStatus(path, into: &statbuf)
            } catch {
              // can't stat file, it's fatal error
              throw error
            }
            if statbuf.fileType != .directory {
              if last {
                // last comp exists but not dir
                throw .fileExists
              } else {
                // parent comp exists but not dir
                throw .notDirectory
              }
            }
          default:
            fatalError()
          }
        }

      }
    }

  }

  public static func remove(_ path: FilePath) throws(Errno) {
    if try fileStatus(path, flags: .noFollow, \.fileType) == .directory {
      try removeDirectoryRecursive(path)
    } else {
      try SystemCall.unlink(path)
    }

  }
  
  /// remove empty directory
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func removeDirectory(_ path: borrowing some CString) throws(Errno) {
    try SystemCall.unlink(path, flags: .removeDir)
  }
  
  /// remove directory tree and prevente directoryNotEmpty Errno
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func removeDirectoryUntilSuccess(_ path: FilePath) throws(Errno) {
    while true {
      do {
        try removeDirectoryRecursive(path)
        return
      } catch .directoryNotEmpty {

      } catch {
        throw error
      }
    }
  }

  public static func removeDirectoryRecursive(_ path: FilePath) throws(Errno) {
    var directory = try Directory.open(path)

    while let entry = try directory.next() {
      // remove each entry, return result
      let entryName = entry.name
      let childPath = path.appending(entryName)
      switch entry.fileType {
      case .directory: try removeDirectoryRecursive(childPath)
      case .unknown: try remove(childPath)
      default:
        try SystemCall.unlink(childPath)
      }
    }

    try removeDirectory(path)
  }

  /// Performs a deep enumeration of the specified directory and returns the paths of all of the contained subdirectories.
  /// - Parameter path: The path of the root directory.
  /// - Returns: Relative paths of all of the contained subdirectories.
  public static func subpathsOfDirectory(atPath path: FilePath) throws(Errno) -> [FilePath] {
    var results = [FilePath]()
    try _subpathsOfDirectory(atPath: path, basePath: FilePath(), into: &results)
    return results
  }

  private static func _subpathsOfDirectory(atPath path: FilePath, basePath: FilePath, into results: inout [FilePath]) throws(Errno) {
    var directory = try Directory.open(path)
    let dfd = directory.fd
    while let entry = try directory.next() {
      let entryName = entry.name
      let result = basePath.appending(entryName)
      results.append(result)

      let isDirectory: Bool = switch entry.fileType {
      case .directory: true
      case .unknown:
        try fileStatus(entryName, relativeTo: .directory(dfd), flags: .noFollow, \.fileType) == .directory
      default: false
      }
      if isDirectory {
        try _subpathsOfDirectory(atPath: path.appending(entryName), basePath: basePath.appending(entryName), into: &results)
      }
    }
  }

  public static func nullDeviceFD() throws(Errno) -> FileDescriptor {
    try SystemCall.open("/dev/null", .readWrite)
  }

}

// MARK: File Contents
public extension SystemFileManager {

  internal static func length(fd: FileDescriptor) throws -> Int {
    let status = try fileStatus(fd, \.size)
    return Int(status)
  }

  internal static func streamRead<T: RangeReplaceableCollection>(fd: FileDescriptor, bufferSize: Int) throws -> T where T.Element == UInt8 {
    precondition(bufferSize > 0)
    var dest = T()
    try withUnsafeTemporaryAllocation(byteCount: bufferSize, alignment: MemoryLayout<UInt>.alignment) { buffer in
      while case let readSize = try fd.read(into: buffer), readSize > 0 {
        dest.append(contentsOf: UnsafeMutableRawBufferPointer(rebasing: buffer.prefix(readSize)))
      }
    }
    return dest
  }

  enum FullContentLoadMode {
    case length
    case stream(bufferSize: Int)
  }

  static func contents(ofFile path: borrowing some CString, mode: FullContentLoadMode = .length) throws -> [UInt8] {
    try SystemCall.open(path, .readOnly)
      .closeAfter { fd in
        try contents(ofFileDescriptor: fd, mode: mode)
      }
  }

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  static func contents(ofFile path: borrowing some CString, mode: FullContentLoadMode = .length) throws -> String {
    try SystemCall.open(path, .readOnly)
      .closeAfter { fd in
        try contents(ofFileDescriptor: fd, mode: mode)
      }
  }


  static func contents(ofFileDescriptor fd: FileDescriptor, mode: FullContentLoadMode = .length) throws -> [UInt8] {
    switch mode {
    case .length:
      let size = try length(fd: fd)
      return try .init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
        initializedCount = try fd.read(into: .init(buffer))
      }
    case .stream(let bufferSize):
      return try streamRead(fd: fd, bufferSize: bufferSize)
    }
  }

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  static func contents(ofFileDescriptor fd: FileDescriptor, mode: FullContentLoadMode = .length) throws -> String {
    switch mode {
    case .length:
      let size = try length(fd: fd)
      return try .init(unsafeUninitializedCapacity: size) { buffer in
        try fd.read(into: UnsafeMutableRawBufferPointer(buffer))
      }
    case .stream(let bufferSize):
      return try .init(decoding: streamRead(fd: fd, bufferSize: bufferSize) as [UInt8], as: UTF8.self)
    }
  }

}

// MARK: Getting and Setting Attributes
public extension SystemFileManager {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileStatus<R>(_ fd: FileDescriptor, _ property: (FileStatus) -> R = { $0 }) throws(Errno) -> R {
    var buf: FileStatus = Memory.undefined()
    try SystemCall.fileStatus(fd, into: &buf)
    return property(buf)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileStatus<R>(_ path: borrowing some CString, relativeTo base: SystemCall.RelativeDirectory = .cwd, flags: SystemCall.AtFlags = [], _ property: (FileStatus) -> R = { $0 }) throws(Errno) -> R {
    var buf: FileStatus = Memory.undefined()
    try path.withUnsafeCString { path throws(Errno) in
      try SystemCall.fileStatus(path, relativeTo: base, flags: flags, into: &buf)
    }
    return property(buf)
  }

}

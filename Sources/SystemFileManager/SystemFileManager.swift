import SystemUp
import struct Foundation.Data
import CUtility

public struct SystemFileManager {}

extension SystemFileManager {

  public static func createDirectoryIntermediately(_ path: FilePath, relativeTo base: SystemCall.RelativeDirectory = .cwd, permissions: FilePermissions = .directoryDefault) throws(Errno) {
    do throws(Errno) {
      let fileType = try fileStatus(path, \.fileType)
      if fileType == .directory {
        // existed
        return
      } else {
        throw Errno.fileExists
      }
    } catch {
      switch error {
      case .noSuchFileOrDirectory:
        // create parent
        var parent = path
        if parent.removeLastComponent(), !parent.isEmpty {
          try createDirectoryIntermediately(parent, relativeTo: base, permissions: permissions)
        }
        try path.withUnsafeCString { path throws(Errno) in
          try SystemCall.createDirectory(path, relativeTo: base, permissions: permissions)
        }
      default:
        throw error
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

  public static func nullDeviceFD() throws -> FileDescriptor {
    try .open("/dev/null", .readWrite)
  }

}

// MARK: File Contents
public extension SystemFileManager {

  private static func length(fd: FileDescriptor) throws -> Int {
    let status = try fileStatus(fd, \.size)
    return Int(status)
  }

  private static func streamRead<T: RangeReplaceableCollection>(fd: FileDescriptor, bufferSize: Int) throws -> T where T.Element == UInt8 {
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

  static func contents(ofFile path: FilePath, mode: FullContentLoadMode = .length) throws -> [UInt8] {
    let fd = try FileDescriptor.open(path, .readOnly)
    return try fd.closeAfter {
      try contents(ofFileDescriptor: fd, mode: mode)
    }
  }

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  static func contents(ofFile path: FilePath, mode: FullContentLoadMode = .length) throws -> String {
    let fd = try FileDescriptor.open(path, .readOnly)
    return try fd.closeAfter {
      try contents(ofFileDescriptor: fd, mode: mode)
    }
  }

  static func contents(ofFile path: FilePath, mode: FullContentLoadMode = .length) throws -> Data {
    let fd = try FileDescriptor.open(path, .readOnly)
    return try fd.closeAfter {
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

  static func contents(ofFileDescriptor fd: FileDescriptor, mode: FullContentLoadMode = .length) throws -> Data {
    switch mode {
    case .length:
      let size = try length(fd: fd)
      guard size > 0 else {
        return .init()
      }
      let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)
      do {
        let count = try fd.read(into: buffer)
        return .init(bytesNoCopy: buffer.baseAddress!, count: count, deallocator: .free)
      } catch {
        buffer.deallocate()
        throw error
      }
    case .stream(let bufferSize):
      return try streamRead(fd: fd, bufferSize: bufferSize)
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

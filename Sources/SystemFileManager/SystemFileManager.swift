import SystemPackage
import SystemUp
import struct Foundation.Data
import CUtility
import CGeneric

public struct SystemFileManager {}

extension SystemFileManager {

  public static func createDirectoryIntermediately(_ path: FilePath, relativeTo base: SystemCall.RelativeDirectory = .cwd, permissions: FilePermissions = .directoryDefault) throws(Errno) {
    var status: FileStatus = Memory.undefined()
    switch SystemCall.fileStatus(path, relativeTo: base, into: &status) {
    case .success:
      if status.fileType == .directory {
        return
      } else {
        throw Errno.fileExists
      }
    case .failure(let err):
      switch err {
      case .noSuchFileOrDirectory:
        // create parent
        var parent = path
        if parent.removeLastComponent(), !parent.isEmpty {
          try createDirectoryIntermediately(parent, relativeTo: base, permissions: permissions)
        }
      default:
        throw err
      }
    }
    try SystemCall.createDirectory(path, relativeTo: base, permissions: permissions).get()
  }

  public static func remove(_ path: FilePath) throws(Errno) {
    if try fileStatus(path, flags: .noFollow, \.fileType).get() == .directory {
      return try removeDirectoryRecursive(path)
    } else {
      return try SystemCall.unlink(path).get()
    }

  }

  public static func removeDirectory(_ path: FilePath) throws(Errno) {
    try SystemCall.unlink(path, flags: .removeDir).get()
  }

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
    let directory = try Directory.open(path)

    while (try directory.withNextEntry({ entry throws(Errno) -> Void in
      // remove each entry, return result
      let entryName = entry.name
      let childPath = path.appending(entryName)
      switch entry.fileType {
      case .directory: try removeDirectoryRecursive(childPath)
      default: try SystemCall.unlink(childPath).get()
      }
    })?.get()) != nil { }

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
    let directory = try Directory.open(path)
    while true {
      let result: ()? = try directory.withNextEntry { nextEntry throws(Errno) in
        let entryName = nextEntry.name
        let result = basePath.appending(entryName)
        results.append(result)
        if nextEntry.fileType == .directory {
          try _subpathsOfDirectory(atPath: path.appending(entryName), basePath: basePath.appending(entryName), into: &results)
        }
      }?.get()

      if result == nil {
        break
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
    let status = try fileStatus(fd).get()
    return Int(status.size)
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

// MARK: Determining Access to Files
public extension SystemFileManager {
  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileExists(atPath path: String, relativeTo base: SystemCall.RelativeDirectory = .cwd) -> Bool {
    switch fileStatus(path, relativeTo: base, { _ in ()}) {
    case .success: return true
    case .failure: return false
    }
  }
}


// MARK: Getting and Setting Attributes
public extension SystemFileManager {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileStatus<R>(_ fd: FileDescriptor, _ property: (FileStatus) -> R = { $0 }) -> Result<R, Errno> {
    withUnsafeTemporaryAllocation(of: FileStatus.self, capacity: 1) { buf in
      SystemCall.fileStatus(fd, into: buf.baseAddress!)
        .map { property(buf[0]) }
    }
  }

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileStatus<R>(_ path: String, relativeTo base: SystemCall.RelativeDirectory = .cwd, flags: SystemCall.AtFlags = [], _ property: (FileStatus) -> R = { $0 }) -> Result<R, Errno> {
    withUnsafeTemporaryAllocation(of: FileStatus.self, capacity: 1) { buf in
      SystemCall.fileStatus(path, relativeTo: base, flags: flags, into: buf.baseAddress!)
        .map { property(buf[0]) }
    }
  }

}

import SystemPackage
import SystemUp
import struct Foundation.Data

public struct SystemFileManager {}

extension SystemFileManager {

  public static func createDirectoryIntermediately(_ path: FilePath, relativeTo base: SystemCall.RelativeDirectory = .cwd, permissions: FilePermissions = .directoryDefault) throws {
    var status = FileStatus(rawValue: .init())
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

  public static func remove(_ path: FilePath) -> Result<Void, Errno> {
    withUnsafeTemporaryAllocation(of: FileStatus.self, capacity: 1) { buffer in
      SystemCall.fileStatus(path, flags: .noFollow, into: &buffer.baseAddress!.pointee)
        .flatMap { () -> Result<Void, Errno> in
          if buffer[0].fileType == .directory {
            return removeDirectoryRecursive(path)
          } else {
            return SystemCall.unlink(path)
          }
        }
    }
  }

  public static func removeDirectory(_ path: FilePath) -> Result<Void, Errno> {
    SystemCall.unlink(path, flags: .removeDir)
  }

  public static func removeDirectoryUntilSuccess(_ path: FilePath) -> Result<Void, Errno> {
    while true {
      switch removeDirectoryRecursive(path) {
      case .success: return .success(())
      case .failure(.directoryNotEmpty):
        break
      case .failure(let err):
        return .failure(err)
      }
    }
  }

  public static func removeDirectoryRecursive(_ path: FilePath) -> Result<Void, Errno> {
    switch Directory.open(path) {
    case .failure(let e): return .failure(e)
    case .success(let directory):
      defer { directory.close() }
      while let result = directory.withNextEntry({ entry -> Result<Void, Errno> in
        // remove each entry, return result
        let entryName = entry.name
        let childPath = path.appending(entryName)
        switch entry.fileType {
        case .directory: return removeDirectoryRecursive(childPath)
        default: return SystemCall.unlink(childPath)
        }
      }) {
        switch result {
        case .failure(let readError): return .failure(readError)
        case .success(let removeResult):
          switch removeResult {
          case .success: break
          case .failure(let removeError): return .failure(removeError)
          }
        }
      }
      return removeDirectory(path)
    }
  }

  /// Performs a deep enumeration of the specified directory and returns the paths of all of the contained subdirectories.
  /// - Parameter path: The path of the root directory.
  /// - Returns: Relative paths of all of the contained subdirectories.
  public static func subpathsOfDirectory(atPath path: FilePath) throws -> [FilePath] {
    var results = [FilePath]()
    try _subpathsOfDirectory(atPath: path, basePath: FilePath(), into: &results)
    return results
  }

  private static func _subpathsOfDirectory(atPath path: FilePath, basePath: FilePath, into results: inout [FilePath]) throws {
    try Directory.open(path)
      .get()
      .closeAfter { directory in
        while true {
          let result: ()? = try directory.withNextEntry { nextEntry in
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
  static func fileExists(atPath path: FilePath, relativeTo base: SystemCall.RelativeDirectory = .cwd) -> Bool {
    switch fileStatus(path, relativeTo: base) {
    case .success: return true
    case .failure: return false
    }
  }
}


// MARK: Getting and Setting Attributes
public extension SystemFileManager {

  static func fileStatus(_ fd: FileDescriptor) -> Result<FileStatus, Errno> {
    var result = FileStatus()
    return SystemCall.fileStatus(fd, into: &result)
      .map { result }
  }

  static func fileStatus(_ path: FilePath, relativeTo base: SystemCall.RelativeDirectory = .cwd, flags: SystemCall.AtFlags = []) -> Result<FileStatus, Errno> {
    var result = FileStatus()
    return SystemCall.fileStatus(path, relativeTo: base, flags: flags, into: &result)
      .map { result }
  }

}

import SystemPackage
import SystemUp
import struct Foundation.Data

public struct SystemFileManager {}

extension SystemFileManager {

  public static func createDirectoryIntermediately(_ option: FilePathOption, permissions: FilePermissions = .directoryDefault) throws {
    var status = FileStatus(rawValue: .init())
    switch FileSyscalls.fileStatus(option, into: &status) {
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
        var parent = option.path
        if parent.removeLastComponent(), !parent.isEmpty {
          try createDirectoryIntermediately(.relative(parent, toDirectory: option.relativedDirFD), permissions: permissions)
        }
      default:
        throw err
      }
    }
    try FileSyscalls.createDirectory(option, permissions: permissions).get()
  }

  public static func remove(_ path: FilePath) -> Result<Void, Errno> {
    var status = FileStatus(rawValue: .init())
    return FileSyscalls.fileStatus(.absolute(path), flags: .noFollow, into: &status)
      .flatMap {
        if status.fileType == .directory {
          return removeDirectoryRecursive(path)
        } else {
          return FileSyscalls.unlink(.absolute(path))
        }
      }
  }

  public static func removeDirectory(_ path: FilePath) -> Result<Void, Errno> {
    FileSyscalls.unlink(.absolute(path), flags: .removeDir)
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
      rootloop: while true {
        switch directory.read() {
        case .failure(let e): return .failure(e)
        case .success(let entry):
          if let entry = entry {
            if entry.pointee.isDot {
              continue rootloop
            }
            let entryName = entry.pointee.name
            let childPath = path.appending(entryName)
            let result: Result<Void, Errno>
            switch entry.pointee.fileType {
            case .directory: result = removeDirectoryRecursive(childPath)
            default: result = FileSyscalls.unlink(.absolute(childPath))
            }
            switch result {
            case .failure(let e): return .failure(e)
            case .success: break
            }
          } else {
            // read finished
            break rootloop
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
        while let nextEntry = try directory.read().get() {
          if nextEntry.pointee.isDot {
            continue
          }
          let entryName = nextEntry.pointee.name
          let result = basePath.appending(entryName)
          results.append(result)
          if nextEntry.pointee.fileType == .directory {
            try _subpathsOfDirectory(atPath: path.appending(entryName), basePath: basePath.appending(entryName), into: &results)
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
    var status = FileStatus(rawValue: .init())
    try FileSyscalls.fileStatus(fd, into: &status).get()
    return Int(status.size)
  }

  static func contents(ofFileDescriptor fd: FileDescriptor) throws -> [UInt8] {
    let size = try length(fd: fd)

    return try .init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
      initializedCount = try fd.read(into: .init(buffer))
    }
  }

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  static func contents(ofFileDescriptor fd: FileDescriptor) throws -> String {
    let size = try length(fd: fd)

    return try .init(unsafeUninitializedCapacity: size) { buffer in
      try fd.read(into: UnsafeMutableRawBufferPointer(buffer))
    }
  }

  static func contents(ofFileDescriptor fd: FileDescriptor) throws -> Data {
    let size = try length(fd: fd)

    let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

    let count = try fd.read(into: buffer)

    return .init(bytesNoCopy: buffer.baseAddress!, count: count, deallocator: .free)
  }

}

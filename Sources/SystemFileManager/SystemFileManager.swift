import SystemUp
import CUtility

public struct SystemFileManager {}

extension SystemFileManager {

  public static func createDirectoryIntermediately(_ path: borrowing some CString, relativeTo base: SystemCall.RelativeDirectory = .cwd, permissions: FilePermissions = .directoryDefault, onDirectoryCreated: (UnsafePointer<CChar>) -> Void = { _ in }, onFailure: (UnsafePointer<CChar>) -> Void = { _ in }) throws(Errno) {
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
          onDirectoryCreated(path) // eg. logging
        } catch {
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
            // mkdir just failed
            onFailure(path)
            throw error
          }
        }

      }
    }

  }

  public static func remove(_ path: borrowing some CString) throws(Errno) {
    if try fileStatus(path, flags: .noFollow, { $0.fileType }) == .directory {
      #if APPLE
      try removeDirectoryUntilSuccess(path)
      #else
      try removeDirectoryRecursive(path)
      #endif
    } else {
      try SystemCall.unlink(path)
    }
  }
  
  /// remove empty directory
  public static func removeDirectory(_ path: borrowing some CString) throws(Errno) {
    try SystemCall.unlink(path, flags: .removeDir)
  }
  
  /// remove directory tree and prevente directoryNotEmpty Errno
  public static func removeDirectoryUntilSuccess(_ path: borrowing some CString) throws(Errno) {
    while true {
      do {
        try removeDirectoryRecursive(path)
        return
      } catch .directoryNotEmpty {
        // happens on darwin sometimes
      } catch {
        throw error
      }
    }
  }

  internal struct RecursiveRemove {
    var sb: FileStatus = Memory.undefined()

    mutating func recursiveAll(_ path: borrowing some CString, relativeTo base: SystemCall.RelativeDirectory) throws(Errno) {
      var directory = try Directory.open(path, relativeTo: base)
      let dfd = directory.fd
      while let entry = try directory.next() {
        // remove each entry, return result
        assert(entry.name != ".")
        assert(entry.name != "..")
        var isDir = false
        switch entry.fileType {
        case .directory: isDir = true
        case .unknown:
          try SystemCall.fileStatus(entry.nameCString, relativeTo: .directory(dfd), flags: .noFollow, into: &sb)
          if sb.fileType == .directory {
            isDir = true
          }
        default:
          break
        }

        if isDir {
          try recursiveAll(entry.nameCString, relativeTo: .directory(dfd))
        }

        try SystemCall.unlink(entry.nameCString, relativeTo: .directory(dfd), flags: isDir ? .removeDir : [])
      }
    }
  }

  public static func removeDirectoryRecursive(_ path: borrowing some CString) throws(Errno) {

    var worker = RecursiveRemove()

    try worker.recursiveAll(path, relativeTo: .cwd)

    try removeDirectory(path)
  }

  public static func nullDeviceFD() throws(Errno) -> FileDescriptor {
    try SystemCall.open("/dev/null", .readWrite)
  }

}

// MARK: File Contents
public extension SystemFileManager {

  internal static func length(fd: FileDescriptor) throws(Errno) -> Int {
    let status = try fileStatus(fd) { $0.size }
    return Int(status)
  }

  internal static func streamRead<T: RangeReplaceableCollection>(fd: FileDescriptor, bufferSize: Int) throws(Errno) -> T where T.Element == UInt8 {
    precondition(bufferSize > 0)
    var dest = T()
    try withUnsafeTemporaryAllocationTyped(byteCount: bufferSize, alignment: MemoryLayout<UInt>.alignment) { buffer throws(Errno) in
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

  static func contents(ofFile path: borrowing some CString, mode: FullContentLoadMode = .length) throws(Errno) -> [UInt8] {
    try SystemCall.open(path, .readOnly)
      .closeAfter { fd throws(Errno) in
        try contents(ofFileDescriptor: fd, mode: mode)
      }
  }

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  static func contents(ofFile path: borrowing some CString, mode: FullContentLoadMode = .length) throws(Errno) -> String {
    try SystemCall.open(path, .readOnly)
      .closeAfter { fd throws(Errno) in
        try contents(ofFileDescriptor: fd, mode: mode)
      }
  }


  static func contents(ofFileDescriptor fd: FileDescriptor, mode: FullContentLoadMode = .length) throws(Errno) -> [UInt8] {
    switch mode {
    case .length:
      let size = try length(fd: fd)
      return try .init(ContiguousArray.create(unsafeUninitializedCapacity: size) { buffer, initializedCount throws(Errno) in
        initializedCount = try fd.read(into: .init(buffer))
      })
    case .stream(let bufferSize):
      return try streamRead(fd: fd, bufferSize: bufferSize)
    }
  }

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  static func contents(ofFileDescriptor fd: FileDescriptor, mode: FullContentLoadMode = .length) throws(Errno) -> String {
    switch mode {
    case .length:
      let size = try length(fd: fd)
      return try .create(unsafeUninitializedCapacity: size) { buffer throws(Errno) in
        try fd.read(into: UnsafeMutableRawBufferPointer(buffer))
      }
    case .stream(let bufferSize):
      return try .init(decoding: streamRead(fd: fd, bufferSize: bufferSize) as [UInt8], as: UTF8.self)
    }
  }

}

// MARK: Getting and Setting Attributes
public extension SystemFileManager {

  @inlinable
  static func fileStatus<R>(_ fd: FileDescriptor, _ property: (FileStatus) -> R = { $0 }) throws(Errno) -> R {
    var buf: FileStatus = Memory.undefined()
    try SystemCall.fileStatus(fd, into: &buf)
    return property(buf)
  }

  @inlinable
  static func fileStatus<R>(_ path: borrowing some CString, relativeTo base: SystemCall.RelativeDirectory = .cwd, flags: SystemCall.AtFlags = [], _ property: (FileStatus) -> R = { $0 }) throws(Errno) -> R {
    var buf: FileStatus = Memory.undefined()
    try path.withUnsafeCString { path throws(Errno) in
      try SystemCall.fileStatus(path, relativeTo: base, flags: flags, into: &buf)
    }
    return property(buf)
  }

}

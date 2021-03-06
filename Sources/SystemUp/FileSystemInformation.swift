import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public extension FileSyscalls {

  static func fileSystemInformation(_ fd: FileDescriptor) -> Result<FileSystemInformation, Errno> {
    var s = FileSystemInformation(rawValue: .init())
    return fileSystemInformation(fd, into: &s).map { s }
  }

  static func fileSystemInformation(_ path: FilePath) throws -> Result<FileSystemInformation, Errno> {
    var s = FileSystemInformation(rawValue: .init())
    return fileSystemInformation(path, into: &s).map { s }
  }

  static func fileSystemInformation(_ fd: FileDescriptor, into s: inout FileSystemInformation) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      fstatvfs(fd.rawValue, &s.rawValue)
    }
  }

  static func fileSystemInformation(_ path: FilePath, into s: inout FileSystemInformation) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        statvfs(path, &s.rawValue)
      }
    }
  }
}

/// POSIX filesystem information
public struct FileSystemInformation: RawRepresentable {
  public init(rawValue: statvfs) {
    self.rawValue = rawValue
  }
  public var rawValue: statvfs
}

public extension FileSystemInformation {

  /// File system block size
  var filesystemBlockSize: UInt {
    rawValue.f_bsize
  }

  /// Fundamental file system block size
  var fundamentalFilesystemBlockSize: UInt {
    rawValue.f_frsize
  }

  /// Blocks on FS in units of f_frsize
  var blocks: fsblkcnt_t {
    rawValue.f_blocks
  }

  /// Free blocks
  var freeBlocks: fsblkcnt_t {
    rawValue.f_bfree
  }

  /// Blocks available to non-root
  var availableBlocks: fsblkcnt_t {
    rawValue.f_bavail
  }

  /// Total inodes
  var totalInodes: fsblkcnt_t {
    rawValue.f_files
  }

  /// Free inodes
  var freeInodes: fsblkcnt_t {
    rawValue.f_ffree
  }

  /// Free inodes for non-root
  var availableInodes: fsblkcnt_t {
    rawValue.f_favail
  }

  var filesystemID: UInt {
    rawValue.f_fsid
  }

  /// Mount flags
  var flags: Flags {
    .init(rawValue: rawValue.f_flag)
  }

  /// Max file name length
  var maxFilenameLength: UInt {
    rawValue.f_namemax
  }

  struct Flags: OptionSet {

    public init(rawValue: UInt) {
      self.rawValue = rawValue
    }

    public var rawValue: UInt
  }

}

public extension FileSystemInformation.Flags {
  @_alwaysEmitIntoClient
  static var readOnly: Self { .init(macroValue: ST_RDONLY) }

  @_alwaysEmitIntoClient
  static var noSetUID: Self { .init(macroValue: ST_NOSUID) }
}

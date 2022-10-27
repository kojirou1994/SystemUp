import CUtility
import SystemLibc

/// POSIX filesystem information
public struct FileSystemInformation: RawRepresentable {
  public init(rawValue: statvfs) {
    self.rawValue = rawValue
  }

  @_alwaysEmitIntoClient
  public init() {
    self.init(rawValue: .init())
  }

  public var rawValue: statvfs
}

public extension FileSystemInformation {

  /// File system block size
  @_alwaysEmitIntoClient
  var filesystemBlockSize: UInt {
    rawValue.f_bsize
  }

  /// Fundamental file system block size
  @_alwaysEmitIntoClient
  var fundamentalFilesystemBlockSize: UInt {
    rawValue.f_frsize
  }

  /// Blocks on FS in units of f_frsize
  @_alwaysEmitIntoClient
  var blocks: fsblkcnt_t {
    rawValue.f_blocks
  }

  /// Free blocks
  @_alwaysEmitIntoClient
  var freeBlocks: fsblkcnt_t {
    rawValue.f_bfree
  }

  /// Blocks available to non-root
  @_alwaysEmitIntoClient
  var availableBlocks: fsblkcnt_t {
    rawValue.f_bavail
  }

  /// Total inodes
  @_alwaysEmitIntoClient
  var totalInodes: fsblkcnt_t {
    rawValue.f_files
  }

  /// Free inodes
  @_alwaysEmitIntoClient
  var freeInodes: fsblkcnt_t {
    rawValue.f_ffree
  }

  /// Free inodes for non-root
  @_alwaysEmitIntoClient
  var availableInodes: fsblkcnt_t {
    rawValue.f_favail
  }

  @_alwaysEmitIntoClient
  var filesystemID: UInt {
    rawValue.f_fsid
  }

  /// Mount flags
  @_alwaysEmitIntoClient
  var flags: Flags {
    .init(rawValue: rawValue.f_flag)
  }

  /// Max file name length
  @_alwaysEmitIntoClient
  var maxFilenameLength: UInt {
    rawValue.f_namemax
  }

  struct Flags: OptionSet, MacroRawRepresentable {

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

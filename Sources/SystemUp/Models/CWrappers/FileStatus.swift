import SystemPackage
import SystemLibc
import CUtility

public struct FileStatus: BitwiseCopyable {

  public var rawValue: stat
}

extension FileStatus: CustomStringConvertible {

  @inline(never)
  public var description: String {
    "FileStatus(deviceID: \(deviceID), fileType: \(fileType), hardLinksCount: \(hardLinksCount), fileSerialNumber: \(fileSerialNumber), userID: \(String(userID, radix: 8, uppercase: true)), specialDeviceID: \(specialDeviceID), size: \(size), blocksCount: \(blocksCount), blockSize: \(blockSize))"
  }
}

public extension FileStatus {

  /// ID of device containing file
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var deviceID: DeviceID {
    .init(rawValue: rawValue.st_dev)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var fileType: FileType {
    .init(rawValue: rawValue.st_mode & S_IFMT)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var permissions: FilePermissions {
    .init(rawValue: rawValue.st_mode & ~S_IFMT)
  }

  /// number of hard links to the file
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var hardLinksCount: CInterop.UpNumberOfLinks {
    rawValue.st_nlink
  }

  /// inode's number
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var fileSerialNumber: CInterop.UpInodeNumber {
    rawValue.st_ino
  }

  /// user-id of owner
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var userID: UInt32 {
    rawValue.st_uid
  }

  /// device type, for special file inode, eg. block or character
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var specialDeviceID: DeviceID {
    .init(rawValue: rawValue.st_rdev)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var lastAccessTime: Timespec {
    #if canImport(Darwin)
    .init(rawValue: rawValue.st_atimespec)
    #elseif canImport(Glibc)
    .init(rawValue: rawValue.st_atim)
    #endif
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var lastModificationTime: Timespec {
    #if canImport(Darwin)
    .init(rawValue: rawValue.st_mtimespec)
    #elseif canImport(Glibc)
    .init(rawValue: rawValue.st_mtim)
    #endif
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var lastStatusChangedTime: Timespec {
    #if canImport(Darwin)
    .init(rawValue: rawValue.st_ctimespec)
    #elseif canImport(Glibc)
    .init(rawValue: rawValue.st_ctim)
    #endif
  }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var creationTime: Timespec {
    .init(rawValue: rawValue.st_birthtimespec)
  }
  #endif

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var size: CInterop.UpSize {
    rawValue.st_size
  }

  /// The actual number of blocks allocated for the file in 512-byte units.  As short symbolic links are stored in the inode, this number may be zero.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var blocksCount: CInterop.UpBlocksCount {
    rawValue.st_blocks
  }

  /// The optimal I/O block size for the file.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var blockSize: CInterop.UpBlockSize {
    rawValue.st_blksize
  }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var flags: UInt32 {
    rawValue.st_flags
  }
  #endif

  #if canImport(Darwin)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var fileGenerationNumber: UInt32 {
    rawValue.st_gen
  }
  #endif

  struct FileType: MacroRawRepresentable, Equatable {

    public init(rawValue: CInterop.Mode) {
      self.rawValue = rawValue
    }

    public let rawValue: CInterop.Mode
  }
}

public extension FileStatus.FileType {
  @_alwaysEmitIntoClient
  static var namedPipe: Self { .init(macroValue: S_IFIFO) }

  @_alwaysEmitIntoClient
  static var character: Self { .init(macroValue: S_IFCHR) }

  @_alwaysEmitIntoClient
  static var directory: Self { .init(macroValue: S_IFDIR) }

  @_alwaysEmitIntoClient
  static var block: Self { .init(macroValue: S_IFBLK) }

  @_alwaysEmitIntoClient
  static var regular: Self { .init(macroValue: S_IFREG) }

  @_alwaysEmitIntoClient
  static var symbolicLink: Self { .init(macroValue: S_IFLNK) }

  @_alwaysEmitIntoClient
  static var socket: Self { .init(macroValue: S_IFSOCK) }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient
  static var wht: Self { .init(macroValue: S_IFWHT) }
  #endif
}

extension FileStatus.FileType: CustomStringConvertible {

  @inline(never)
  public var description: String {
    switch self {
    case .namedPipe: return "namedPipe"
    case .character: return "character"
    case .directory: return "directory"
    case .block: return "block"
    case .regular: return "regular"
    case .symbolicLink: return "symbolicLink"
    case .socket: return "socket"
    #if canImport(Darwin)
    case .wht: return "wht"
    #endif
    default: return unknownDescription
    }
  }

}

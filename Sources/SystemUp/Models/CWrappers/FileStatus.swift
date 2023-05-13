import SystemPackage
import SystemLibc
import CUtility

public struct FileStatus {
  public init(rawValue: CInterop.UpStat) {
    self.rawValue = rawValue
  }

  @_alwaysEmitIntoClient
  public init() {
    self.init(rawValue: .init())
  }

  public var rawValue: CInterop.UpStat
}

extension FileStatus: CustomStringConvertible {

  @inline(never)
  public var description: String {
    "FileStatus(deviceID: \(deviceID), fileType: \(fileType), hardLinksCount: \(hardLinksCount), fileSerialNumber: \(fileSerialNumber), userID: \(String(userID, radix: 8, uppercase: true)), specialDeviceID: \(specialDeviceID), size: \(size), blocksCount: \(blocksCount), blockSize: \(blockSize))"
  }
}

public extension FileStatus {

  /// ID of device containing file
  @_alwaysEmitIntoClient
  var deviceID: DeviceID {
    .init(rawValue: rawValue.st_dev)
  }

  @_alwaysEmitIntoClient
  var fileType: FileType {
    .init(rawValue: rawValue.st_mode & S_IFMT)
  }

  @_alwaysEmitIntoClient
  var permissions: FilePermissions {
    .init(rawValue: rawValue.st_mode & ~S_IFMT)
  }

  /// number of hard links to the file
  @_alwaysEmitIntoClient
  var hardLinksCount: CInterop.UpNumberOfLinks {
    rawValue.st_nlink
  }

  /// inode's number
  @_alwaysEmitIntoClient
  var fileSerialNumber: CInterop.UpInodeNumber {
    rawValue.st_ino
  }

  /// user-id of owner
  @_alwaysEmitIntoClient
  var userID: UInt32 {
    rawValue.st_uid
  }

  /// device type, for special file inode, eg. block or character
  @_alwaysEmitIntoClient
  var specialDeviceID: DeviceID {
    .init(rawValue: rawValue.st_rdev)
  }

  @_alwaysEmitIntoClient
  var lastAccessTime: CInterop.UpTimespec {
    #if canImport(Darwin)
    rawValue.st_atimespec
    #elseif canImport(Glibc)
    rawValue.st_atim
    #endif
  }

  @_alwaysEmitIntoClient
  var lastModificationTime: CInterop.UpTimespec {
    #if canImport(Darwin)
    rawValue.st_mtimespec
    #elseif canImport(Glibc)
    rawValue.st_mtim
    #endif
  }

  @_alwaysEmitIntoClient
  var lastStatusChangedTime: CInterop.UpTimespec {
    #if canImport(Darwin)
    rawValue.st_ctimespec
    #elseif canImport(Glibc)
    rawValue.st_ctim
    #endif
  }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient
  var creationTime: CInterop.UpTimespec {
    rawValue.st_birthtimespec
  }
  #endif

  @_alwaysEmitIntoClient
  var size: CInterop.UpSize {
    rawValue.st_size
  }

  /// The actual number of blocks allocated for the file in 512-byte units.  As short symbolic links are stored in the inode, this number may be zero.
  @_alwaysEmitIntoClient
  var blocksCount: CInterop.UpBlocksCount {
    rawValue.st_blocks
  }

  /// The optimal I/O block size for the file.
  @_alwaysEmitIntoClient
  var blockSize: CInterop.UpBlockSize {
    rawValue.st_blksize
  }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient
  var flags: UInt32 {
    rawValue.st_flags
  }
  #endif

  #if canImport(Darwin)
  @_alwaysEmitIntoClient
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

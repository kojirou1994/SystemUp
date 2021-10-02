import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

public struct FileStatus {
  
  @_alwaysEmitIntoClient
  public init() {
    self.status = .init()
  }
  
  @_alwaysEmitIntoClient
  internal var status: stat
}

extension FileStatus: CustomStringConvertible {

  @inline(never)
  public var description: String {
    "FileStatus(deviceID: \(deviceID), fileType: \(fileType), hardLinksCount: \(hardLinksCount), fileSerialNumber: \(fileSerialNumber), userID: \(String(userID, radix: 8, uppercase: true)), rDeviceID: \(rDeviceID), lastAccessTime: \(lastAccessTime), lastModificationTime: \(lastModificationTime), lastStatusChangedTime: \(lastStatusChangedTime), creationTime: \(creationTime), size: \(size), blocksCount: \(blocksCount), blockSize: \(blockSize), flags: \(flags), fileGenerationNumber: \(fileGenerationNumber))"
  }

  @_alwaysEmitIntoClient
  public var deviceID: Int32 {
    status.st_dev
  }

  @_alwaysEmitIntoClient
  public var fileType: FileType {
    .init(rawValue: status.st_mode & S_IFMT)
  }

  @_alwaysEmitIntoClient
  public var permissions: FilePermissions {
    .init(rawValue: status.st_mode & ~S_IFMT)
  }

  @_alwaysEmitIntoClient
  public var hardLinksCount: UInt16 {
    status.st_nlink
  }

  @_alwaysEmitIntoClient
  public var fileSerialNumber: UInt64 {
    status.st_ino
  }

  @_alwaysEmitIntoClient
  public var userID: UInt32 {
    status.st_uid
  }

  @_alwaysEmitIntoClient
  public var rDeviceID: Int32 {
    status.st_rdev
  }

  @_alwaysEmitIntoClient
  public var lastAccessTime: timespec {
    status.st_atimespec
  }

  @_alwaysEmitIntoClient
  public var lastModificationTime: timespec {
    status.st_mtimespec
  }

  @_alwaysEmitIntoClient
  public var lastStatusChangedTime: timespec {
    status.st_ctimespec
  }

  @_alwaysEmitIntoClient
  public var creationTime: timespec {
    status.st_birthtimespec
  }

  @_alwaysEmitIntoClient
  public var size: Int {
    Int(status.st_size)
  }

  @_alwaysEmitIntoClient
  /// The actual number of blocks allocated for the file in 512-byte units.  As short symbolic links are stored in the inode, this number may be zero.
  public var blocksCount: Int {
    Int(status.st_blocks)
  }

  @_alwaysEmitIntoClient
  /// The optimal I/O block size for the file.
  public var blockSize: Int {
    Int(status.st_blksize)
  }

  @_alwaysEmitIntoClient
  public var flags: UInt32 {
    status.st_flags
  }

  @_alwaysEmitIntoClient
  public var fileGenerationNumber: UInt32 {
    status.st_gen
  }

  public struct FileType: RawRepresentable, Equatable {

    @_alwaysEmitIntoClient
    public init(rawValue: mode_t) {
      self.rawValue = rawValue
    }
    @_alwaysEmitIntoClient
    internal init(_ rawValue: mode_t) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public let rawValue: mode_t
  }
}

extension FileStatus.FileType {
  @_alwaysEmitIntoClient
  public static var namedPipe: Self { .init(S_IFIFO) }

  @_alwaysEmitIntoClient
  public static var character: Self { .init(S_IFCHR) }

  @_alwaysEmitIntoClient
  public static var directory: Self { .init(S_IFDIR) }

  @_alwaysEmitIntoClient
  public static var block: Self { .init(S_IFBLK) }

  @_alwaysEmitIntoClient
  public static var regular: Self { .init(S_IFREG) }

  @_alwaysEmitIntoClient
  public static var symbolicLink: Self { .init(S_IFLNK) }

  @_alwaysEmitIntoClient
  public static var socket: Self { .init(S_IFSOCK) }

  @_alwaysEmitIntoClient
  public static var wht: Self { .init(S_IFWHT) }
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
    case .wht: return "wht"
    default: return "unknown"
    }
  }

}

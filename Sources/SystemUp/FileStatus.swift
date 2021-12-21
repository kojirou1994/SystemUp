import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

public struct FileStatus {
  internal init(status: stat) {
    self.status = status
  }
  
  public init() {
    self.status = .init()
  }
  
  internal var status: stat
}

extension FileStatus: CustomStringConvertible {

  @inline(never)
  public var description: String {
    "FileStatus(deviceID: \(deviceID), fileType: \(fileType), hardLinksCount: \(hardLinksCount), fileSerialNumber: \(fileSerialNumber), userID: \(String(userID, radix: 8, uppercase: true)), rDeviceID: \(rDeviceID), lastAccessTime: \(lastAccessTime), lastModificationTime: \(lastModificationTime), lastStatusChangedTime: \(lastStatusChangedTime), creationTime: \(creationTime), size: \(size), blocksCount: \(blocksCount), blockSize: \(blockSize), flags: \(flags), fileGenerationNumber: \(fileGenerationNumber))"
  }

  public var deviceID: Int32 {
    status.st_dev
  }

  public var fileType: FileType {
    .init(rawValue: status.st_mode & S_IFMT)
  }

  public var permissions: FilePermissions {
    .init(rawValue: status.st_mode & ~S_IFMT)
  }

  public var hardLinksCount: UInt16 {
    status.st_nlink
  }

  public var fileSerialNumber: UInt64 {
    status.st_ino
  }

  public var userID: UInt32 {
    status.st_uid
  }

  public var rDeviceID: Int32 {
    status.st_rdev
  }

  public var lastAccessTime: timespec {
    status.st_atimespec
  }

  public var lastModificationTime: timespec {
    status.st_mtimespec
  }

  public var lastStatusChangedTime: timespec {
    status.st_ctimespec
  }

  public var creationTime: timespec {
    status.st_birthtimespec
  }

  public var size: Int {
    Int(status.st_size)
  }

  /// The actual number of blocks allocated for the file in 512-byte units.  As short symbolic links are stored in the inode, this number may be zero.
  public var blocksCount: Int {
    Int(status.st_blocks)
  }

  /// The optimal I/O block size for the file.
  public var blockSize: Int {
    Int(status.st_blksize)
  }

  public var flags: UInt32 {
    status.st_flags
  }

  public var fileGenerationNumber: UInt32 {
    status.st_gen
  }

  public struct FileType: RawRepresentable, Equatable {

    public init(rawValue: mode_t) {
      self.rawValue = rawValue
    }
    internal init(_ rawValue: mode_t) {
      self.rawValue = rawValue
    }

    public let rawValue: mode_t
  }
}

extension FileStatus.FileType {
  public static var namedPipe: Self { .init(S_IFIFO) }

  public static var character: Self { .init(S_IFCHR) }

  public static var directory: Self { .init(S_IFDIR) }

  public static var block: Self { .init(S_IFBLK) }

  public static var regular: Self { .init(S_IFREG) }

  public static var symbolicLink: Self { .init(S_IFLNK) }

  public static var socket: Self { .init(S_IFSOCK) }

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

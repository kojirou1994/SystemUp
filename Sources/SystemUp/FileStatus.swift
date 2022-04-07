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
    "FileStatus(deviceID: \(deviceID), fileType: \(fileType), hardLinksCount: \(hardLinksCount), fileSerialNumber: \(fileSerialNumber), userID: \(String(userID, radix: 8, uppercase: true)), rDeviceID: \(rDeviceID), size: \(size), blocksCount: \(blocksCount), blockSize: \(blockSize))"
  }

  public var deviceID: CInterop.UpDev {
    status.st_dev
  }

  public var fileType: FileType {
    .init(rawValue: status.st_mode & S_IFMT)
  }

  public var permissions: FilePermissions {
    .init(rawValue: status.st_mode & ~S_IFMT)
  }

  public var hardLinksCount: CInterop.UpNumberOfLinks {
    status.st_nlink
  }

  public var fileSerialNumber: CInterop.UpInodeNumber {
    status.st_ino
  }

  public var userID: UInt32 {
    status.st_uid
  }

  public var rDeviceID: CInterop.UpDev {
    status.st_rdev
  }

  #if canImport(Darwin)
  public var lastAccessTime: timespec {
    status.st_atimespec
  }
  #endif

  #if canImport(Darwin)
  public var lastModificationTime: timespec {
    status.st_mtimespec
  }
  #endif

  #if canImport(Darwin)
  public var lastStatusChangedTime: timespec {
    status.st_ctimespec
  }
  #endif

  #if canImport(Darwin)
  public var creationTime: timespec {
    status.st_birthtimespec
  }
  #endif

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

  #if canImport(Darwin)
  public var flags: UInt32 {
    status.st_flags
  }
  #endif

  #if canImport(Darwin)
  public var fileGenerationNumber: UInt32 {
    status.st_gen
  }
  #endif

  public struct FileType: RawRepresentable, Equatable {

    public init(rawValue: mode_t) {
      self.rawValue = rawValue
    }

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

  #if canImport(Darwin)
  @_alwaysEmitIntoClient
  public static var wht: Self { .init(S_IFWHT) }
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
    default: return "unknown"
    }
  }

}

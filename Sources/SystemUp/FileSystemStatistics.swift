import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import CSystemUp
import CUtility

public extension FileSyscalls {

  static func fileSystemStatistics(_ fd: FileDescriptor) -> Result<FileSystemStatistics, Errno> {
    var s = FileSystemStatistics(rawValue: .init())
    return fileSystemStatistics(fd, into: &s).map { s }
  }

  static func fileSystemStatistics(_ path: FilePath) throws -> Result<FileSystemStatistics, Errno> {
    var s = FileSystemStatistics(rawValue: .init())
    return fileSystemStatistics(path, into: &s).map { s }
  }

  static func fileSystemStatistics(_ fd: FileDescriptor, into s: inout FileSystemStatistics) -> Result<Void, Errno> {
    voidOrErrno {
      fstatfs(fd.rawValue, &s.rawValue)
    }
  }

  static func fileSystemStatistics(_ path: FilePath, into s: inout FileSystemStatistics) -> Result<Void, Errno> {
    voidOrErrno {
      path.withPlatformString { path in
        statfs(path, &s.rawValue)
      }
    }
  }
}

public struct FileSystemStatistics: RawRepresentable {

  /// the c struct
  public var rawValue: statfs

  public init(rawValue: statfs) {
    self.rawValue = rawValue
  }

}

@available(macOS 10.15, iOS 13.0, *)
public extension FileSystemStatistics {

  #if canImport(Darwin)
  typealias BlockSize = UInt32
  typealias UpFSWord = UInt64
  #elseif os(Linux)
  typealias BlockSize = __fsword_t
  typealias UpFSWord = __fsword_t
  #endif

  /// fundamental file system block size
  var blockSize: BlockSize {
    rawValue.f_bsize
  }

  #if canImport(Darwin)
  /// optimal transfer block size
  var ioSize: Int32 {
    rawValue.f_iosize
  }
  #endif

  /// total data blocks in file system
  var blocks: some FixedWidthInteger {
    rawValue.f_blocks
  }

  /// free blocks in fs
  var freeBlocks: some FixedWidthInteger {
    rawValue.f_bfree
  }

  /// free blocks avail to non-superuser
  var availableBlocks: some FixedWidthInteger {
    rawValue.f_bavail
  }

  /// total file nodes in file system
  var nodes: some FixedWidthInteger {
    rawValue.f_files
  }

  /// free file nodes in fs
  var freeNodes: some FixedWidthInteger {
    rawValue.f_ffree
  }

  /// file system id
  var id: (Int32, Int32) {
    #if canImport(Darwin)
    rawValue.f_fsid.val
    #else
    rawValue.f_fsid.__val
    #endif
  }

  #if canImport(Darwin)
  /// user that mounted the filesystem
  var owner: uid_t {
    rawValue.f_owner
  }
  #endif

  /// type of filesystem
  var type: some FixedWidthInteger {
    rawValue.f_type
  }

  #if canImport(Darwin)
  /// fs sub-type (flavor)
  var subType: UInt32 {
    rawValue.f_fssubtype
  }

  /// fs type name
  var typeName: String {
    String(cStackString: rawValue.f_fstypename)
  }
  #endif

  /// copy of mount exported flags
  var flags: some FixedWidthInteger {
    rawValue.f_flags
  }

  #if canImport(Darwin)
  /// directory on which mounted
  var mountedOnName: String {
    String(cStackString: rawValue.f_mntonname)
  }

  /// mounted filesystem
  var mountedFileSystem: String {
    String.init(cStackString: rawValue.f_mntfromname)
  }
  #endif

}

//public extension FileSystemStatistics {
//
//  var usedNodes: UInt64 {
//    nodes - freeNodes
//  }
//
//  var usedBlocks: UInt64 {
//    blocks - freeBlocks
//  }
//
//}

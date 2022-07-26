#if canImport(Darwin)
import SystemPackage
import Darwin
import SyscallValue
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
    nothingOrErrno(retryOnInterrupt: false) {
      fstatfs(fd.rawValue, &s.rawValue)
    }
  }

  static func fileSystemStatistics(_ path: FilePath, into s: inout FileSystemStatistics) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
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

public extension FileSystemStatistics {
  /// fundamental file system block size
  var blockSize: UInt32 {
    rawValue.f_bsize
  }

  /// optimal transfer block size
  var ioSize: Int32 {
    rawValue.f_iosize
  }

  /// total data blocks in file system
  var blocks: UInt64 {
    rawValue.f_blocks
  }

  /// free blocks in fs
  var freeBlocks: UInt64 {
    rawValue.f_bfree
  }

  /// free blocks avail to non-superuser
  var freeBlocksNonSuperuser: UInt64 {
    rawValue.f_bavail
  }

  /// total file nodes in file system
  var nodes: UInt64 {
    rawValue.f_files
  }

  /// free file nodes in fs
  var freeNodes: UInt64 {
    rawValue.f_ffree
  }

  /// file system id
  var id: fsid {
    rawValue.f_fsid
  }

  /// user that mounted the filesystem
  var owner: uid_t {
    rawValue.f_owner
  }

  /// type of filesystem
  var type: UInt32 {
    rawValue.f_type
  }

  /// fs sub-type (flavor)
  var subType: UInt32 {
    rawValue.f_fssubtype
  }

  /// fs type name
  var typeName: String {
    String(cStackString: rawValue.f_fstypename)
  }

  /// copy of mount exported flags
  var flags: UInt32 {
    rawValue.f_flags
  }

  /// directory on which mounted
  var mountedOnName: String {
    String(cStackString: rawValue.f_mntonname)
  }

  /// mounted filesystem
  var mountedFileSystem: String {
    String.init(cStackString: rawValue.f_mntfromname)
  }
}

public extension FileSystemStatistics {

  var usedNodes: UInt64 {
    nodes - freeNodes
  }

  var usedBlocks: UInt64 {
    blocks - freeBlocks
  }

}

#endif // Darwin platform

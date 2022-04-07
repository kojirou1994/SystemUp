#if canImport(Darwin)
import SystemPackage
import Darwin
import SyscallValue
import CUtility

public extension FileUtility {

  static func fileSystemStatistics(_ fd: FileDescriptor) throws -> FileSystemStatistics {
    var s = FileSystemStatistics()
    try fileSystemStatistics(fd, into: &s)
    return s
  }

  static func fileSystemStatistics(_ path: FilePath) throws -> FileSystemStatistics {
    var s = FileSystemStatistics()
    try fileSystemStatistics(path, into: &s)
    return s
  }

  static func fileSystemStatistics(_ fd: FileDescriptor, into s: inout FileSystemStatistics) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      fstatfs(fd.rawValue, &s.value)
    }.get()
  }

  static func fileSystemStatistics(_ path: FilePath, into s: inout FileSystemStatistics) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      path.withPlatformString { path in
        statfs(path, &s.value)
      }
    }.get()
  }
}

public struct FileSystemStatistics {

  /// the c struct
  fileprivate var value: statfs

  public init() {
    self.value = .init()
  }

}

extension FileSystemStatistics: CustomStringConvertible {

  @inline(never)
  public var description: String {
    "FileSystemStatistics(blockSize: \(blockSize), ioSize: \(ioSize), blocks: \(blocks), freeBlocks: \(freeBlocks), freeBlocksNonSuperuser: \(freeBlocksNonSuperuser), nodes: \(nodes), freeNodes: \(freeNodes), usedNodes: \(usedNodes), id: \(id), owner: \(owner), type: \(type), flags: \(flags), subType: \(subType), typeName: \(typeName), mountedOnName: \(mountedOnName), mountedFileSystem: \(mountedFileSystem))"
  }

}

public extension FileSystemStatistics {
  /// fundamental file system block size
  var blockSize: UInt32 {
    value.f_bsize
  }

  /// optimal transfer block size
  var ioSize: Int32 {
    value.f_iosize
  }

  /// total data blocks in file system
  var blocks: UInt64 {
    value.f_blocks
  }

  /// free blocks in fs
  var freeBlocks: UInt64 {
    value.f_bfree
  }

  /// free blocks avail to non-superuser
  var freeBlocksNonSuperuser: UInt64 {
    value.f_bavail
  }

  /// total file nodes in file system
  var nodes: UInt64 {
    value.f_files
  }

  /// free file nodes in fs
  var freeNodes: UInt64 {
    value.f_ffree
  }

  /// file system id
  var id: fsid {
    value.f_fsid
  }

  /// user that mounted the filesystem
  var owner: uid_t {
    value.f_owner
  }

  /// type of filesystem
  var type: UInt32 {
    value.f_type
  }

  /// fs sub-type (flavor)
  var subType: UInt32 {
    value.f_fssubtype
  }

  /// fs type name
  var typeName: String {
    String(cStackString: value.f_fstypename)
  }

  /// copy of mount exported flags
  var flags: UInt32 {
    value.f_flags
  }

  /// directory on which mounted
  var mountedOnName: String {
    String(cStackString: value.f_mntonname)
  }

  /// mounted filesystem
  var mountedFileSystem: String {
    String.init(cStackString: value.f_mntfromname)
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

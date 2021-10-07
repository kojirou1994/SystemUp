import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import SyscallValue
import KwiftC

public extension FileUtility {

  @_alwaysEmitIntoClient
  static func fileSystemStatistics(_ fd: FileDescriptor) throws -> FileSystemStatistics {
    var s = FileSystemStatistics()
    try fileSystemStatistics(fd, into: &s)
    return s
  }

  @_alwaysEmitIntoClient
  static func fileSystemStatistics(_ path: FilePath) throws -> FileSystemStatistics {
    var s = FileSystemStatistics()
    try fileSystemStatistics(path, into: &s)
    return s
  }

  @_alwaysEmitIntoClient
  static func fileSystemStatistics(_ fd: FileDescriptor, into s: inout FileSystemStatistics) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      fstatfs(fd.rawValue, &s.value)
    }.get()
  }

  @_alwaysEmitIntoClient
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
  @_alwaysEmitIntoClient
  fileprivate var value: statfs

  @_alwaysEmitIntoClient
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
  @_alwaysEmitIntoClient
  var blockSize: UInt32 {
    value.f_bsize
  }

  /// optimal transfer block size
  @_alwaysEmitIntoClient
  var ioSize: Int32 {
    value.f_iosize
  }

  /// total data blocks in file system
  @_alwaysEmitIntoClient
  var blocks: UInt64 {
    value.f_blocks
  }

  /// free blocks in fs
  @_alwaysEmitIntoClient
  var freeBlocks: UInt64 {
    value.f_bfree
  }

  /// free blocks avail to non-superuser
  @_alwaysEmitIntoClient
  var freeBlocksNonSuperuser: UInt64 {
    value.f_bavail
  }

  /// total file nodes in file system
  @_alwaysEmitIntoClient
  var nodes: UInt64 {
    value.f_files
  }

  /// free file nodes in fs
  @_alwaysEmitIntoClient
  var freeNodes: UInt64 {
    value.f_ffree
  }

  /// file system id
  @_alwaysEmitIntoClient
  var id: fsid {
    value.f_fsid
  }

  /// user that mounted the filesystem
  @_alwaysEmitIntoClient
  var owner: uid_t {
    value.f_owner
  }

  /// type of filesystem
  @_alwaysEmitIntoClient
  var type: UInt32 {
    value.f_type
  }

  /// fs sub-type (flavor)
  @_alwaysEmitIntoClient
  var subType: UInt32 {
    value.f_fssubtype
  }

  /// fs type name
  @_alwaysEmitIntoClient
  var typeName: String {
    String(cStackString: value.f_fstypename)
  }

  /// copy of mount exported flags
  @_alwaysEmitIntoClient
  var flags: UInt32 {
    value.f_flags
  }

  /// directory on which mounted
  @_alwaysEmitIntoClient
  var mountedOnName: String {
    String(cStackString: value.f_mntonname)
  }

  /// mounted filesystem
  @_alwaysEmitIntoClient
  var mountedFileSystem: String {
    String.init(cStackString: value.f_mntfromname)
  }
}

public extension FileSystemStatistics {

  @_alwaysEmitIntoClient
  var usedNodes: UInt64 {
    nodes - freeNodes
  }

  @_alwaysEmitIntoClient
  var usedBlocks: UInt64 {
    blocks - freeBlocks
  }

}

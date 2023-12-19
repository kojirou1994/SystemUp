#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import CSystemUp
import CUtility

public struct FileSystemStatistics: RawRepresentable {

  /// the c struct
  public var rawValue: statfs

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: statfs) {
    self.rawValue = rawValue
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() {
    self.init(rawValue: .init())
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
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var blockSize: BlockSize {
    rawValue.f_bsize
  }

  #if canImport(Darwin)
  /// optimal transfer block size
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var ioSize: Int32 {
    rawValue.f_iosize
  }
  #endif

  /// total data blocks in file system
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var blocks: some FixedWidthInteger {
    rawValue.f_blocks
  }

  /// free blocks in fs
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var freeBlocks: some FixedWidthInteger {
    rawValue.f_bfree
  }

  /// free blocks avail to non-superuser
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var availableBlocks: some FixedWidthInteger {
    rawValue.f_bavail
  }

  /// total file nodes in file system
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var nodes: some FixedWidthInteger {
    rawValue.f_files
  }

  /// free file nodes in fs
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var freeNodes: some FixedWidthInteger {
    rawValue.f_ffree
  }

  /// file system id
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var id: (Int32, Int32) {
    #if canImport(Darwin)
    rawValue.f_fsid.val
    #else
    rawValue.f_fsid.__val
    #endif
  }

  #if canImport(Darwin)
  /// user that mounted the filesystem
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var owner: UserID {
    .init(rawValue: rawValue.f_owner)
  }
  #endif

  /// type of filesystem
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var type: some FixedWidthInteger {
    rawValue.f_type
  }

  #if canImport(Darwin)
  /// fs sub-type (flavor)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var subType: UInt32 {
    rawValue.f_fssubtype
  }

  /// fs type name
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var typeName: String {
    String(cStackString: rawValue.f_fstypename)
  }
  #endif

  /// copy of mount exported flags
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var flags: some FixedWidthInteger {
    rawValue.f_flags
  }

  #if canImport(Darwin)
  /// directory on which mounted
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var mountedOnName: String {
    String(cStackString: rawValue.f_mntonname)
  }

  /// mounted filesystem
  @_alwaysEmitIntoClient @inlinable @inline(__always)
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

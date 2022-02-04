import CProc
import CUtility
import SystemPackage

public struct VnodeInfo {
  @_alwaysEmitIntoClient
  private var info: vnode_info

  public init() {
    info = .init()
  }
}

public extension VnodeInfo {

  @_alwaysEmitIntoClient
  var stat: vinfo_stat { info.vi_stat }

  @_alwaysEmitIntoClient
  var type: Int32 { info.vi_type }

  @_alwaysEmitIntoClient
  var pad: Int32 { info.vi_pad }

  @_alwaysEmitIntoClient
  var fsid: fsid_t { info.vi_fsid }
}

extension VnodeInfo: CustomStringConvertible {
  public var description: String {
    "VnodeInfo(stat: \(stat), type: \(type), pad: \(pad), fsid: \(fsid))"
  }
}

extension VnodeInfo {
  public struct Status {
    @_alwaysEmitIntoClient
    private var status: vinfo_stat

    public init() {
      status = .init()
    }
  }
}

public extension VnodeInfo.Status {

  @_alwaysEmitIntoClient
  var deviceID: UInt32 {
    status.vst_dev
  }

//  public var fileType: FileType {
//    .init(rawValue: status.vst_mode & S_IFMT)
//  }


  @_alwaysEmitIntoClient
  var permissions: FilePermissions {
    .init(rawValue: status.vst_mode & ~S_IFMT)
  }

  @_alwaysEmitIntoClient
  var hardLinksCount: UInt16 {
    status.vst_nlink
  }

  @_alwaysEmitIntoClient
  var fileSerialNumber: UInt64 {
    status.vst_ino
  }

  @_alwaysEmitIntoClient
  var userID: UInt32 {
    status.vst_uid
  }

  @_alwaysEmitIntoClient
  var groupID: UInt32 {
    status.vst_gid
  }

  @_alwaysEmitIntoClient
  var lastAccessTime: Int64 {
    status.vst_atime
  }

  @_alwaysEmitIntoClient
  var lastAccessTimeNSec: Int64 {
    status.vst_atimensec
  }

  @_alwaysEmitIntoClient
  var lastModificationTime: Int64 {
    status.vst_mtime
  }

  @_alwaysEmitIntoClient
  var lastModificationTimeNSec: Int64 {
    status.vst_mtimensec
  }

  @_alwaysEmitIntoClient
  var lastStatusChangedTime: Int64 {
    status.vst_ctime
  }

  @_alwaysEmitIntoClient
  var lastStatusChangedTimeNSec: Int64 {
    status.vst_ctimensec
  }

  @_alwaysEmitIntoClient
  var creationTime: Int64 {
    status.vst_birthtime
  }

  @_alwaysEmitIntoClient
  var size: Int64 {
    status.vst_size
  }

  /// The actual number of blocks allocated for the file in 512-byte units.  As short symbolic links are stored in the inode, this number may be zero.
  @_alwaysEmitIntoClient
  var blocksCount: Int64 {
    status.vst_blocks
  }

  /// The optimal I/O block size for the file.
  @_alwaysEmitIntoClient
  var blockSize: Int32 {
    status.vst_blksize
  }

  @_alwaysEmitIntoClient
  var flags: UInt32 {
    status.vst_flags
  }

  @_alwaysEmitIntoClient
  var fileGenerationNumber: UInt32 {
    status.vst_gen
  }
}

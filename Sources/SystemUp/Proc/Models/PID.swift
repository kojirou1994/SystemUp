#if os(macOS)
import CUtility
import SystemLibc
import SystemPackage

extension Proc {
  public struct BSDInfo {
    @usableFromInline
    internal let info: proc_bsdinfo
  }
}

public extension Proc.BSDInfo {

  @_alwaysEmitIntoClient
  var flags: Flags {
    .init(rawValue: info.pbi_flags)
  }

  @_alwaysEmitIntoClient
  var status: UInt32 { info.pbi_flags }

  @_alwaysEmitIntoClient
  var xstatus: UInt32 { info.pbi_xstatus }

  @_alwaysEmitIntoClient
  var pid: UInt32 { info.pbi_pid }

  @_alwaysEmitIntoClient
  var ppid: UInt32 { info.pbi_ppid }

  @_alwaysEmitIntoClient
  var uid: UserID { .init(rawValue: info.pbi_uid) }

  @_alwaysEmitIntoClient
  var gid: GroupProcessID { .init(rawValue: info.pbi_gid) }

  @_alwaysEmitIntoClient
  var ruid: UserID { .init(rawValue: info.pbi_ruid) }

  @_alwaysEmitIntoClient
  var rgid: GroupProcessID { .init(rawValue: info.pbi_rgid) }

  @_alwaysEmitIntoClient
  var svuid: UserID { .init(rawValue: info.pbi_svuid) }

  @_alwaysEmitIntoClient
  var svgid: GroupProcessID { .init(rawValue: info.pbi_svgid) }

  @_alwaysEmitIntoClient
  var comm: String {
    .init(cStackString: info.pbi_comm)
  }

  @_alwaysEmitIntoClient
  var name: String {
    .init(cStackString: info.pbi_name)
  }

  @_alwaysEmitIntoClient
  var nfiles: UInt32 { info.pbi_nfiles }

  @_alwaysEmitIntoClient
  var pgid: UInt32 { info.pbi_pgid }

  @_alwaysEmitIntoClient
  var pjobc: UInt32 { info.pbi_pjobc }

  @_alwaysEmitIntoClient
  var e_tdev: UInt32  { info.e_tdev }

  @_alwaysEmitIntoClient
  var e_tpgid: UInt32  { info.e_tpgid }

  @_alwaysEmitIntoClient
  var nice: Int32 { info.pbi_nice }

  @_alwaysEmitIntoClient
  var start_tvsec: UInt64 { info.pbi_start_tvsec }

  @_alwaysEmitIntoClient
  var start_tvusec: UInt64 { info.pbi_start_tvusec }
}

extension Proc.BSDInfo {
  public struct Flags: OptionSet, MacroRawRepresentable {
    @_alwaysEmitIntoClient
    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    public let rawValue: UInt32
  }
}
/*
 public var PROC_FLAG_INEXIT: Int32 { get } /*  */
 public var PROC_FLAG_PPWAIT: Int32 { get }
 public var PROC_FLAG_LP64: Int32 { get } /* 64bit process */
 public var PROC_FLAG_SLEADER: Int32 { get } /* The process is the session leader */
 public var PROC_FLAG_CTTY: Int32 { get } /* process has a control tty */
 public var PROC_FLAG_CONTROLT: Int32 { get } /* Has a controlling terminal */
 public var PROC_FLAG_THCWD: Int32 { get } /* process has a thread with cwd */
 /* process control bits for resource starvation */
 public var PROC_FLAG_PC_THROTTLE: Int32 { get } /* In resource starvation situations, this process is to be throttled */
 public var PROC_FLAG_PC_SUSP: Int32 { get } /* In resource starvation situations, this process is to be suspended */
 public var PROC_FLAG_PC_KILL: Int32 { get } /* In resource starvation situations, this process is to be terminated */
 public var PROC_FLAG_PC_MASK: Int32 { get }
 /* process action bits for resource starvation */
 public var PROC_FLAG_PA_THROTTLE: Int32 { get } /* The process is currently throttled due to resource starvation */
 public var PROC_FLAG_PA_SUSP: Int32 { get } /* The process is currently suspended due to resource starvation */
 public var PROC_FLAG_PSUGID: Int32 { get } /* process has set privileges since last exec */
 public var PROC_FLAG_EXEC: Int32 { get } /* process has called exec  */
 */
public extension Proc.BSDInfo.Flags {
  /// System process
  @_alwaysEmitIntoClient
  static var system: Self { .init(macroValue: PROC_FLAG_SYSTEM) }

  /// process currently being traced, possibly by gdb
  @_alwaysEmitIntoClient
  static var traced: Self { .init(macroValue: PROC_FLAG_TRACED) }

  /// process is working its way in exit()
  @_alwaysEmitIntoClient
  static var inExit: Self { .init(macroValue: PROC_FLAG_INEXIT) }
}

extension Proc {
  public struct BSDShortInfo {
    @usableFromInline
    internal let info: proc_bsdshortinfo
  }
}
public extension Proc.BSDShortInfo {
  @_alwaysEmitIntoClient
  var flags: UInt32 { info.pbsi_flags }

  @_alwaysEmitIntoClient
  var status: UInt32 { info.pbsi_flags }

  @_alwaysEmitIntoClient
  var processID: UInt32 { info.pbsi_pid }

  @_alwaysEmitIntoClient
  var processParentID: UInt32 { info.pbsi_ppid }

  @_alwaysEmitIntoClient
  var uid: UserID { .init(rawValue: info.pbsi_uid) }

  @_alwaysEmitIntoClient
  var gid: GroupProcessID { .init(rawValue: info.pbsi_gid) }

  @_alwaysEmitIntoClient
  var ruid: UserID { .init(rawValue: info.pbsi_ruid) }

  @_alwaysEmitIntoClient
  var rgid: GroupProcessID { .init(rawValue: info.pbsi_rgid) }

  @_alwaysEmitIntoClient
  var svuid: UserID { .init(rawValue: info.pbsi_svuid) }

  @_alwaysEmitIntoClient
  var svgid: GroupProcessID { .init(rawValue: info.pbsi_svgid) }

  @_alwaysEmitIntoClient
  var comm: String {
    .init(cStackString: info.pbsi_comm)
  }

  @_alwaysEmitIntoClient
  var processPerpID: UInt32 { info.pbsi_pgid }

}

extension Proc {
  public struct FDInfo {
    @usableFromInline
    internal let info: proc_fdinfo

    public struct FDType: MacroRawRepresentable, Equatable {
      @_alwaysEmitIntoClient
      public init(rawValue: UInt32) {
        self.rawValue = rawValue
      }
      public let rawValue: UInt32
    }
  }
}

public extension Proc.FDInfo {

  @_alwaysEmitIntoClient
  var fd: FileDescriptor { .init(rawValue: info.proc_fd) }

  @_alwaysEmitIntoClient
  var fdtype: FDType {
    .init(rawValue: info.proc_fdtype)
  }

}

extension Proc.FDInfo: CustomStringConvertible {
  public var description: String {
    "FDInfo(fd: \(info.proc_fd), type: \(fdtype))"
  }
}

public extension Proc.FDInfo.FDType {
  @_alwaysEmitIntoClient
  static var atalk: Self { .init(macroValue: PROX_FDTYPE_ATALK) }

  @_alwaysEmitIntoClient
  static var vnode: Self { .init(macroValue: PROX_FDTYPE_VNODE) }

  @_alwaysEmitIntoClient
  static var socket: Self { .init(macroValue: PROX_FDTYPE_SOCKET) }

  @_alwaysEmitIntoClient
  static var pshm: Self { .init(macroValue: PROX_FDTYPE_PSHM) }

  @_alwaysEmitIntoClient
  static var psem: Self { .init(macroValue: PROX_FDTYPE_PSEM) }

  @_alwaysEmitIntoClient
  static var kqueue: Self { .init(macroValue: PROX_FDTYPE_KQUEUE) }

  @_alwaysEmitIntoClient
  static var pipe: Self { .init(macroValue: PROX_FDTYPE_PIPE) }

  @_alwaysEmitIntoClient
  static var fsEvents: Self { .init(macroValue: PROX_FDTYPE_FSEVENTS) }

  @_alwaysEmitIntoClient
  static var netPolicy: Self { .init(macroValue: PROX_FDTYPE_NETPOLICY) }
}

extension Proc.FDInfo.FDType: CustomStringConvertible {
  public var description: String {
    switch self {
    case .atalk: return "atalk"
    case .vnode: return "vnode"
    case .socket: return "socket"
    case .pshm: return "pshm"
    case .psem: return "psem"
    case .kqueue: return "kqueue"
    case .pipe: return "pipe"
    case .fsEvents: return "fsEvents"
    case .netPolicy: return "netPolicy"
    default: return "unknown(\(rawValue))"
    }
  }
}

extension Proc {
  public struct FileInfo {
    @usableFromInline
    internal let info: proc_fileinfo
  }
}

public extension Proc.FileInfo {

  @_alwaysEmitIntoClient
  var openFlags: UInt32 { info.fi_openflags }

  @_alwaysEmitIntoClient
  var status: UInt32 { info.fi_status }

  @_alwaysEmitIntoClient
  var offset: Int64 { info.fi_offset }

  @_alwaysEmitIntoClient
  var type: Int32 { info.fi_type }

  @_alwaysEmitIntoClient
  var guardFlags: UInt32 { info.fi_guardflags }

}

extension Proc.FileInfo: CustomStringConvertible {
  public var description: String {
    "FileInfo(openFlags: \(openFlags), status: \(status), offset: \(offset), type: \(type), guardFlags: \(guardFlags))"
  }
}

extension Proc {
  public struct FilePortInfo {
    @usableFromInline
    internal let info: proc_fileportinfo
  }
}

public extension Proc.FilePortInfo {
  @_alwaysEmitIntoClient
  var fileport: UInt32 { info.proc_fileport }

  @_alwaysEmitIntoClient
  var fdtype: UInt32 { info.proc_fdtype }
}

extension Proc {
  public struct TaskAllInfo {
    @usableFromInline
    internal let info: proc_taskallinfo
  }
}
public extension Proc.TaskAllInfo {

  @_alwaysEmitIntoClient
  var bsdInfo: Proc.BSDInfo {
    unsafeBitCast(info.pbsd, to: Proc.BSDInfo.self)
  }

  @_alwaysEmitIntoClient
  var taskInfo: Proc.TaskInfo {
    unsafeBitCast(info.ptinfo, to: Proc.TaskInfo.self)
  }

}

extension Proc {
  public struct TaskInfo {
    @usableFromInline
    internal let info: proc_taskinfo
  }
}

public extension Proc.TaskInfo {

  /// virtual memory size (bytes)
  @_alwaysEmitIntoClient
  var virtualMemorySize: UInt64 { info.pti_virtual_size }

  /// resident memory size (bytes)
  @_alwaysEmitIntoClient
  var residentMemorySize: UInt64 { info.pti_resident_size }

  @_alwaysEmitIntoClient
  var totalUserTime: UInt64 { info.pti_total_user }

  @_alwaysEmitIntoClient
  var totalSystemTime: UInt64 { info.pti_total_system }

  /// existing threads only
  @_alwaysEmitIntoClient
  var threadsUser: UInt64 { info.pti_threads_user }

  @_alwaysEmitIntoClient
  var threadsSystem: UInt64 { info.pti_threads_system }

  /// default policy for new threads
  @_alwaysEmitIntoClient
  var policy: Int32 { info.pti_policy }

  /// number of page faults
  @_alwaysEmitIntoClient
  var pageFaultsCount: Int32 { info.pti_faults }

  /// number of actual pageins
  @_alwaysEmitIntoClient
  var pageinsCount: Int32 { info.pti_pageins }

  /// number of copy-on-write faults
  @_alwaysEmitIntoClient
  var cowFaultsCount: Int32 { info.pti_cow_faults }

  /// number of messages sent
  @_alwaysEmitIntoClient
  var messagesSentCount: Int32 { info.pti_messages_sent }

  /// number of messages received
  @_alwaysEmitIntoClient
  var messagesReceivedCount: Int32 { info.pti_messages_received }

  /// number of mach system calls
  @_alwaysEmitIntoClient
  var machSyscallsCount: Int32 { info.pti_syscalls_mach }

  /// number of unix system calls
  @_alwaysEmitIntoClient
  var unixSyscallsCount: Int32 { info.pti_syscalls_unix }

  /// number of context switches
  @_alwaysEmitIntoClient
  var contextSwitchesCount: Int32 { info.pti_csw }

  /// number of threads in the task
  @_alwaysEmitIntoClient
  var threadsCount: Int32 { info.pti_threadnum }

  /// number of running threads
  @_alwaysEmitIntoClient
  var runningThreadsCount: Int32 { info.pti_numrunning }

  /// task priority
  @_alwaysEmitIntoClient
  var priority: Int32 { info.pti_priority }

}

extension Proc {
  public struct VnodeFDInfo {
    @usableFromInline
    internal let info: vnode_fdinfo
  }
}
public extension Proc.VnodeFDInfo {

  @_alwaysEmitIntoClient
  var fileInfo: Proc.FileInfo {
    unsafeBitCast(info.pfi, to: Proc.FileInfo.self)
  }

  @_alwaysEmitIntoClient
  var vnodeInfo: Proc.VnodeInfo {
    unsafeBitCast(info.pvi, to: Proc.VnodeInfo.self)
  }

}

extension Proc.VnodeFDInfo: CustomStringConvertible {
  public var description: String {
    "VnodeFDInfo(fileInfo: \(fileInfo), vnodeInfo: \(vnodeInfo))"
  }
}

extension Proc {
  public struct VnodeFDInfoWithPath {
    @usableFromInline
    internal let info: vnode_fdinfowithpath
  }
}

public extension Proc.VnodeFDInfoWithPath {

  @_alwaysEmitIntoClient
  var fileInfo: Proc.FileInfo {
    unsafeBitCast(info.pfi, to: Proc.FileInfo.self)
  }

  @_alwaysEmitIntoClient
  var vnodeInfoPath: Proc.VnodeInfoPath {
    unsafeBitCast(info.pvip, to: Proc.VnodeInfoPath.self)
  }

}

extension Proc.VnodeFDInfoWithPath: CustomStringConvertible {
  public var description: String {
    "VnodeFDInfoWithPath(fileInfo: \(fileInfo), vnodeInfoPath: \(vnodeInfoPath))"
  }
}

extension Proc {
  public struct VnodeInfo {
    @usableFromInline
    internal let info: vnode_info
  }
}

public extension Proc.VnodeInfo {

  @_alwaysEmitIntoClient
  var stat: vinfo_stat { info.vi_stat }

  @_alwaysEmitIntoClient
  var type: Int32 { info.vi_type }

  @_alwaysEmitIntoClient
  var pad: Int32 { info.vi_pad }

  @_alwaysEmitIntoClient
  var fsid: fsid_t { info.vi_fsid }
}

extension Proc.VnodeInfo: CustomStringConvertible {
  public var description: String {
    "VnodeInfo(stat: \(stat), type: \(type), pad: \(pad), fsid: \(fsid))"
  }
}

extension Proc.VnodeInfo {
  public struct Status {
    @usableFromInline
    internal let status: vinfo_stat
  }
}

public extension Proc.VnodeInfo.Status {

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

extension Proc {
  public struct VnodeInfoPath {
    @usableFromInline
    internal let info: vnode_info_path
  }
}

public extension Proc.VnodeInfoPath {

  @_alwaysEmitIntoClient
  var vnodeInfo: Proc.VnodeInfo {
    unsafeBitCast(info.vip_vi, to: Proc.VnodeInfo.self)
  }

  @_alwaysEmitIntoClient
  var path: String { .init(cStackString: info.vip_path) }
}

extension Proc.VnodeInfoPath: CustomStringConvertible {
  public var description: String {
    "VnodeInfoPath(vnodeInfo: \(vnodeInfo), path: \(path))"
  }
}

extension Proc {
  public struct VnodePathInfo {
    @usableFromInline
    internal let info: proc_vnodepathinfo
  }
}

public extension Proc.VnodePathInfo {

  @_alwaysEmitIntoClient
  var cdir: Proc.VnodeInfoPath {
    unsafeBitCast(info.pvi_cdir, to: Proc.VnodeInfoPath.self)
  }

  @_alwaysEmitIntoClient
  var rdir: Proc.VnodeInfoPath {
    unsafeBitCast(info.pvi_rdir, to: Proc.VnodeInfoPath.self)
  }

}

#endif

import CProc
import CUtility

public struct BSDInfo {

  private var info: proc_bsdinfo

  public init() {
    info = .init()
  }

}

public extension BSDInfo {
  var flags: Flags {
    .init(rawValue: info.pbi_flags)
  }

  var status: UInt32 { info.pbi_flags }

  var xstatus: UInt32 { info.pbi_xstatus }

  var pid: UInt32 { info.pbi_pid }

  var ppid: UInt32 { info.pbi_ppid }

  var uid: uid_t { info.pbi_uid }

  var gid: gid_t { info.pbi_gid }

  var ruid: uid_t { info.pbi_ruid }

  var rgid: gid_t { info.pbi_rgid }

  var svuid: uid_t { info.pbi_svuid }

  var svgid: gid_t { info.pbi_svgid }

  //  public var rfu_1: UInt32 /* reserved */

  var comm: String {
    .init(cStackString: info.pbi_comm)
  }

  var name: String {
    .init(cStackString: info.pbi_name)
  }

  var nfiles: UInt32 { info.pbi_nfiles }

  var pgid: UInt32 { info.pbi_pgid }

  var pjobc: UInt32 { info.pbi_pjobc }

  var e_tdev: UInt32  { info.e_tdev }

  var e_tpgid: UInt32  { info.e_tpgid }

  var nice: Int32 { info.pbi_nice }

  var start_tvsec: UInt64 { info.pbi_start_tvsec }

  var start_tvusec: UInt64 { info.pbi_start_tvusec }
}

extension BSDInfo {
  public struct Flags: OptionSet {
    @_alwaysEmitIntoClient
    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    private init(_ rawValue: Int32) {
      self.rawValue = .init(bitPattern: rawValue)
    }

    public let rawValue: UInt32
  }
}
/*
 public var PROC_FLAG_SYSTEM: Int32 { get } /*  System process */
 public var PROC_FLAG_TRACED: Int32 { get } /* process currently being traced, possibly by gdb */
 public var PROC_FLAG_INEXIT: Int32 { get } /* process is working its way in exit() */
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
public extension BSDInfo.Flags {
  @_alwaysEmitIntoClient
  static var system: Self { .init(PROC_FLAG_SYSTEM) }
}

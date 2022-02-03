import CProc
import CUtility

public struct BSDShortInfo {

  private var info: proc_bsdshortinfo

  public init() {
    info = .init()
  }

}

public extension BSDShortInfo {
  var flags: UInt32 { info.pbsi_flags }

  var status: UInt32 { info.pbsi_flags }

  var processID: UInt32 { info.pbsi_pid }

  var processParentID: UInt32 { info.pbsi_ppid }

  var uid: uid_t { info.pbsi_uid }

  var gid: gid_t { info.pbsi_gid }

  var ruid: uid_t { info.pbsi_ruid }

  var rgid: gid_t { info.pbsi_rgid }

  var svuid: uid_t { info.pbsi_svuid }

  var svgid: gid_t { info.pbsi_svgid }

  var comm: String {
    .init(cStackString: info.pbsi_comm)
  }

  var processPerpID: UInt32 { info.pbsi_pgid }

}

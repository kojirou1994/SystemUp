import CProc
import CUtility

public struct BSDShortInfo {

  @_alwaysEmitIntoClient
  private var info: proc_bsdshortinfo

  public init() {
    info = .init()
  }

}

public extension BSDShortInfo {
  @_alwaysEmitIntoClient
  var flags: UInt32 { info.pbsi_flags }

  @_alwaysEmitIntoClient
  var status: UInt32 { info.pbsi_flags }

  @_alwaysEmitIntoClient
  var processID: UInt32 { info.pbsi_pid }

  @_alwaysEmitIntoClient
  var processParentID: UInt32 { info.pbsi_ppid }

  @_alwaysEmitIntoClient
  var uid: uid_t { info.pbsi_uid }

  @_alwaysEmitIntoClient
  var gid: gid_t { info.pbsi_gid }

  @_alwaysEmitIntoClient
  var ruid: uid_t { info.pbsi_ruid }

  @_alwaysEmitIntoClient
  var rgid: gid_t { info.pbsi_rgid }

  @_alwaysEmitIntoClient
  var svuid: uid_t { info.pbsi_svuid }

  @_alwaysEmitIntoClient
  var svgid: gid_t { info.pbsi_svgid }

  @_alwaysEmitIntoClient
  var comm: String {
    .init(cStackString: info.pbsi_comm)
  }

  @_alwaysEmitIntoClient
  var processPerpID: UInt32 { info.pbsi_pgid }

}

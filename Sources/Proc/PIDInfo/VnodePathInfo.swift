import CProc
import CUtility

public struct VnodePathInfo {

  @_alwaysEmitIntoClient
  private var info: proc_vnodepathinfo

  public init() {
    info = .init()
  }

}

public extension VnodePathInfo {

  @_alwaysEmitIntoClient
  var cdir: VnodeInfoPath {
    unsafeBitCast(info.pvi_cdir, to: VnodeInfoPath.self)
  }

  @_alwaysEmitIntoClient
  var rdir: VnodeInfoPath {
    unsafeBitCast(info.pvi_rdir, to: VnodeInfoPath.self)
  }

}

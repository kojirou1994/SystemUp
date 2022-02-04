import CProc
import CUtility

public struct VnodeInfoPath {
  @_alwaysEmitIntoClient
  private var info: vnode_info_path

  public init() {
    info = .init()
  }
}

public extension VnodeInfoPath {

  @_alwaysEmitIntoClient
  var vnodeInfo: VnodeInfo {
    unsafeBitCast(info.vip_vi, to: VnodeInfo.self)
  }

  @_alwaysEmitIntoClient
  var path: String { .init(cStackString: info.vip_path) }
}

extension VnodeInfoPath: CustomStringConvertible {
  public var description: String {
    "VnodeInfoPath(vnodeInfo: \(vnodeInfo), path: \(path))"
  }
}

import CProc
import CUtility

public struct VnodeFDInfo {
  @_alwaysEmitIntoClient
  private var info: vnode_fdinfo

  public init() {
    info = .init()
  }
}

public extension VnodeFDInfo {

  @_alwaysEmitIntoClient
  var fileInfo: FileInfo {
    unsafeBitCast(info.pfi, to: FileInfo.self)
  }

  @_alwaysEmitIntoClient
  var vnodeInfo: VnodeInfo {
    unsafeBitCast(info.pvi, to: VnodeInfo.self)
  }

}

extension VnodeFDInfo: CustomStringConvertible {
  public var description: String {
    "VnodeFDInfo(fileInfo: \(fileInfo), vnodeInfo: \(vnodeInfo))"
  }
}

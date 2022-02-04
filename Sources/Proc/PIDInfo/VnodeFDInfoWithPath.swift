import CProc
import CUtility

public struct VnodeFDInfoWithPath {
  @_alwaysEmitIntoClient
  private var info: vnode_fdinfowithpath

  public init() {
    info = .init()
  }
}

public extension VnodeFDInfoWithPath {

  @_alwaysEmitIntoClient
  var fileInfo: FileInfo {
    unsafeBitCast(info.pfi, to: FileInfo.self)
  }

  @_alwaysEmitIntoClient
  var vnodeInfoPath: VnodeInfoPath {
    unsafeBitCast(info.pvip, to: VnodeInfoPath.self)
  }

}

extension VnodeFDInfoWithPath: CustomStringConvertible {
  public var description: String {
    "VnodeFDInfoWithPath(fileInfo: \(fileInfo), vnodeInfoPath: \(vnodeInfoPath))"
  }
}

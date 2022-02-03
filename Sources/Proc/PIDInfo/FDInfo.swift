import CProc

public struct FDInfo {

  @_alwaysEmitIntoClient
  private var info: proc_fdinfo

  public init() {
    info = .init()
  }

}

public extension FDInfo {
  @_alwaysEmitIntoClient
  var fd: Int32 { info.proc_fd }

  @_alwaysEmitIntoClient
  var fdtype: UInt32 { info.proc_fdtype }
}

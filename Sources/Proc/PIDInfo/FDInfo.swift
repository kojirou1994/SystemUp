import CProc

public struct FDInfo {

  private var info: proc_fdinfo

  public init() {
    info = .init()
  }

}

public extension FDInfo {
  var fd: Int32 { info.proc_fd }

  var fdtype: UInt32 { info.proc_fdtype }
}

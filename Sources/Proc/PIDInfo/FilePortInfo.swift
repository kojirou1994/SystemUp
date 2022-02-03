import CProc

public struct FilePortInfo {

  @_alwaysEmitIntoClient
  private var info: proc_fileportinfo

  public init() {
    info = .init()
  }

}

public extension FilePortInfo {
  @_alwaysEmitIntoClient
  var fileport: UInt32 { info.proc_fileport }

  @_alwaysEmitIntoClient
  var fdtype: UInt32 { info.proc_fdtype }
}

import CProc

public struct FilePortInfo {

  private var info: proc_fileportinfo

  public init() {
    info = .init()
  }

}

public extension FilePortInfo {
  var fileport: UInt32 { info.proc_fileport }

  var fdtype: UInt32 { info.proc_fdtype }
}

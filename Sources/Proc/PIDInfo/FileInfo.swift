import CProc
import CUtility

public struct FileInfo {

  @_alwaysEmitIntoClient
  private var info: proc_fileinfo

  public init() {
    info = .init()
  }

}

public extension FileInfo {

  @_alwaysEmitIntoClient
  var openFlags: UInt32 { info.fi_openflags }

  @_alwaysEmitIntoClient
  var status: UInt32 { info.fi_status }

  @_alwaysEmitIntoClient
  var offset: Int64 { info.fi_offset }

  @_alwaysEmitIntoClient
  var type: Int32 { info.fi_type }

  @_alwaysEmitIntoClient
  var guardFlags: UInt32 { info.fi_guardflags }

}

extension FileInfo: CustomStringConvertible {
  public var description: String {
    "FileInfo(openFlags: \(openFlags), status: \(status), offset: \(offset), type: \(type), guardFlags: \(guardFlags))"
  }
}

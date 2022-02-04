import CProc
import SystemPackage

public enum PIDFDInfo { }

public extension PIDFDInfo {
  @_alwaysEmitIntoClient
  static func vnodeInfo(pid: Int32, fd: FileDescriptor, into info: inout VnodeFDInfo) throws {
    try oneTimeSyscall(body: { ptr, bufferSize in
      proc_pidfdinfo(pid, fd.rawValue, PROC_PIDFDVNODEINFO, ptr, bufferSize)
    }, value: &info)
  }

  @_alwaysEmitIntoClient
  static func vnodeInfoWithPath(pid: Int32, fd: FileDescriptor, into info: inout VnodeFDInfoWithPath) throws {
    try oneTimeSyscall(body: { ptr, bufferSize in
      proc_pidfdinfo(pid, fd.rawValue, PROC_PIDFDVNODEPATHINFO, ptr, bufferSize)
    }, value: &info)
  }
}

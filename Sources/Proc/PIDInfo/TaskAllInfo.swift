import CProc

public struct TaskAllInfo {

  @_alwaysEmitIntoClient
  private var info: proc_taskallinfo

  public init() {
    info = .init()
  }

}

public extension TaskAllInfo {

  @_alwaysEmitIntoClient
  var bsdInfo: BSDInfo {
    unsafeBitCast(info.pbsd, to: BSDInfo.self)
  }

  @_alwaysEmitIntoClient
  var taskInfo: TaskInfo {
    unsafeBitCast(info.ptinfo, to: TaskInfo.self)
  }

}

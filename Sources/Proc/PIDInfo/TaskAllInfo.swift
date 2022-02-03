import CProc

public struct TaskAllInfo {

  private var info: proc_taskallinfo

  public init() {
    info = .init()
  }

}

public extension TaskAllInfo {

  var bsdInfo: BSDInfo {
    unsafeBitCast(info.pbsd, to: BSDInfo.self)
  }

  var taskInfo: TaskInfo {
    unsafeBitCast(info.ptinfo, to: TaskInfo.self)
  }

}

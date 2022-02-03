import XCTest
import Proc

final class ProcTests: XCTestCase {
  func testBSDInfo() throws {
    func getpid() -> pid_t {
      40812
    }
    var info = BSDInfo()
    var si = BSDShortInfo()
    var taskInfo = TaskInfo()
    var allInfo = TaskAllInfo()
//    for _ in 0...1_000_000 {
    try PIDInfo.bsdInfo(pid: getpid(), into: &info)
    try PIDInfo.bsdShortInfo(pid: getpid(), into: &si)
    try PIDInfo.taskAllInfo(pid: getpid(), into: &allInfo)
    try PIDInfo.taskInfo(pid: getpid(), into: &taskInfo)
//    }
    print(info.comm)
    dump(info)
    dump(si)
    dump(taskInfo)
    dump(allInfo)
    pause()
  }

  func testWork() {
    print(Proc.libversion)
  }
}

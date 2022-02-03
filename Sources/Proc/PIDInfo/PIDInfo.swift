import CProc
import SystemPackage

public enum PIDInfo { }

public extension PIDInfo {

  @_alwaysEmitIntoClient
  static func taskAllInfo(pid: Int32, into info: inout TaskAllInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDTASKALLINFO, arg: 0, value: &info)
  }

  @_alwaysEmitIntoClient
  static func bsdInfo(pid: Int32, into info: inout BSDInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDTBSDINFO, arg: 0, value: &info)
  }

  @_alwaysEmitIntoClient
  static func taskInfo(pid: Int32, into info: inout TaskInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDTASKINFO, arg: 0, value: &info)
  }

  @_alwaysEmitIntoClient
  static func bsdShortInfo(pid: Int32, into info: inout BSDShortInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDT_SHORTBSDINFO, arg: 0, value: &info)
  }

}

@_alwaysEmitIntoClient
private func pidInfo<T>(pid: Int32, flavor: Int32, arg: UInt64, value: inout T) throws {
  let result = proc_pidinfo(pid, flavor, arg, &value, numericCast(MemoryLayout<T>.size))
  if result <= 0 {
    throw Errno(rawValue: errno)
  }
  if result != numericCast(MemoryLayout<T>.size) {
    assertionFailure()
    throw Errno.outOfRange
  }
}

@_alwaysEmitIntoClient
private func listPIDs(type: UInt32, typeinfo: UInt32, extending: (Int) -> Int = { $0 }) throws -> ContiguousArray<pid_t> {
  let bufsize = Int(proc_listpids(type, typeinfo, nil, 0))
  assert(bufsize % MemoryLayout<pid_t>.size == 0)
  return try .init(unsafeUninitializedCapacity: extending(bufsize / MemoryLayout<pid_t>.size)) { buffer, initializedCount in
    let result = Int(proc_listpids(type, typeinfo, buffer.baseAddress, Int32(buffer.count)))
    if result <= 0 {
      throw Errno(rawValue: errno)
    }

    assert(result % MemoryLayout<pid_t>.size == 0)

    initializedCount = result / MemoryLayout<pid_t>.size
  }
}

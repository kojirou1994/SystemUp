import CProc
import SystemPackage

public enum PIDInfo { }

public extension PIDInfo {

  @_alwaysEmitIntoClient
  static func listFDs(pid: Int32) throws -> [FDInfo] {
    try twiceSyscall(body: { ptr, buffersize in
      proc_pidinfo(pid, PROC_PIDLISTFDS, 0, ptr, buffersize)
    })
  }

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

  @_alwaysEmitIntoClient
  static func vnodePathInfo(pid: Int32, into info: inout VnodePathInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDVNODEPATHINFO, arg: 0, value: &info)
  }

}

import SyscallValue

@usableFromInline
internal func twiceSyscall<S: FixedWidthInteger, R: SyscallValue>(
  body: (_ ptr: UnsafeMutableRawPointer?, _ bufferSize: S) -> S,
  validating: (S) -> Bool = { $0 != -1 },
  extending: (S) -> S = { $0 }) throws -> R {
    let bufsize = body(nil, 0)
    guard validating(bufsize) else {
      throw Errno(rawValue: errno)
    }
    let capacity = extending(bufsize)
    return try R(capacity: Int(capacity)) { ptr in
      let realsize = body(ptr, capacity)
      guard validating(realsize) else {
        throw Errno(rawValue: errno)
      }
      precondition(realsize <= capacity)
      return Int(realsize)
    }
}

@usableFromInline
internal func oneTimeSyscall<S: FixedWidthInteger, R>(
  body: (_ ptr: UnsafeMutableRawPointer, _ bufferSize: S) -> S,
  validating: (S) -> Bool = { $0 > 0 },
  value: inout R) throws {
    assert(MemoryLayout<R>.size > 0)
    let result = body(&value, numericCast(MemoryLayout<R>.size))
    guard validating(result) else {
      throw Errno(rawValue: errno)
    }
    if result != numericCast(MemoryLayout<R>.size) {
      assertionFailure()
      throw Errno.outOfRange
    }
  }

@_alwaysEmitIntoClient
private func pidInfo<T>(pid: Int32, flavor: Int32, arg: UInt64, value: inout T) throws {
  try oneTimeSyscall(body: { ptr, bufferSize in
    proc_pidinfo(pid, flavor, arg, ptr, bufferSize)
  }, value: &value)
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

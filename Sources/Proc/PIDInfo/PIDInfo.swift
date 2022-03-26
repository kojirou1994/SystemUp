import CProc
import SystemPackage

public enum PIDInfo { }

public extension PIDInfo {

  static func listFDs(pid: Int32) throws -> [FDInfo] {
    try twiceSyscall(body: { buffer, buffersize in
      proc_pidinfo(pid, PROC_PIDLISTFDS, 0, buffer, buffersize)
    })
  }

  static func taskAllInfo(pid: Int32, into info: inout TaskAllInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDTASKALLINFO, arg: 0, value: &info)
  }

  static func bsdInfo(pid: Int32, into info: inout BSDInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDTBSDINFO, arg: 0, value: &info)
  }

  static func taskInfo(pid: Int32, into info: inout TaskInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDTASKINFO, arg: 0, value: &info)
  }

  static func bsdShortInfo(pid: Int32, into info: inout BSDShortInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDT_SHORTBSDINFO, arg: 0, value: &info)
  }

  static func vnodePathInfo(pid: Int32, into info: inout VnodePathInfo) throws {
    try pidInfo(pid: pid, flavor: PROC_PIDVNODEPATHINFO, arg: 0, value: &info)
  }

}

import SyscallValue

@usableFromInline
internal func twiceSyscall<S: FixedWidthInteger, R: SyscallValue>(
  body: (_ buffer: UnsafeMutableRawPointer?, _ bufferSize: S) -> S,
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
  body: (_ buffer: UnsafeMutableRawPointer, _ bufferSize: S) -> S,
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

private func pidInfo<T>(pid: Int32, flavor: Int32, arg: UInt64, value: inout T) throws {
  try oneTimeSyscall(body: { buffer, bufferSize in
    proc_pidinfo(pid, flavor, arg, buffer, bufferSize)
  }, value: &value)
}

private func listPIDs(type: UInt32, typeinfo: UInt32, extending: (Int) -> Int = { $0 }) throws -> [Int32] {
  let bufsize = Int(proc_listpids(type, typeinfo, nil, 0))
  assert(bufsize % MemoryLayout<Int32>.stride == 0)
  let pidCapacity = extending(bufsize / MemoryLayout<Int32>.stride)
  return try .init(unsafeUninitializedCapacity: pidCapacity) { buffer, initializedCount in
    let rawBuffer = UnsafeMutableRawBufferPointer(buffer)
    let result = Int(proc_listpids(type, typeinfo, rawBuffer.baseAddress, Int32(rawBuffer.count)))
    if result <= 0 {
      throw Errno(rawValue: errno)
    }

    #if DEBUG
    if bufsize != result {
      print(#function, "buffer size changed from \(bufsize) to \(result)")
    }
    #endif
    assert(result % MemoryLayout<Int32>.stride == 0)

    initializedCount = result / MemoryLayout<Int32>.stride
  }
}

public enum ListPIDs { }

public extension ListPIDs {
  static func listAll() throws -> [Int32] {
    try listPIDs(type: UInt32(PROC_ALL_PIDS), typeinfo: 0)
  }
}

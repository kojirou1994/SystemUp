#if canImport(Darwin)
import SystemLibc
import SystemPackage
import CUtility
import SyscallValue

public enum Proc { }

public extension Proc {

  @_alwaysEmitIntoClient
  static var libVersion: (major: Int32, minor: Int32) {
    var v: (Int32, Int32) = (0, 0)
    proc_libversion(&v.0, &v.1)
    return v
  }

  @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
  @_alwaysEmitIntoClient
  static func name(pid: ProcessID) throws -> String {
    try .init(unsafeUninitializedCapacity: Int(MAXPATHLEN)) { buffer in
      Int(try name(pid: pid, into: .init(buffer)).get())
    }
  }

  /// result is c-string length(no \0), return 0 if buffer is too small
  @_alwaysEmitIntoClient
  static func name(pid: ProcessID, into buffer: UnsafeMutableRawBufferPointer) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      proc_name(pid.rawValue, buffer.baseAddress, numericCast(buffer.count))
    }
  }

    // NOTE: macro PROC_PIDPATHINFO_MAXSIZE is unavailable
  @_alwaysEmitIntoClient
  static var pathInfoMaxSize: Int32 { 4 * MAXPATHLEN }
  
  @_alwaysEmitIntoClient
  static func path(pid: ProcessID) throws -> FilePath {
    try withUnsafeTemporaryAllocation(byteCount: Int(pathInfoMaxSize), alignment: MemoryLayout<UInt8>.alignment) { buffer in
      _ = try path(pid: pid, into: buffer).get()
      return .init(platformString: buffer.baseAddress!.assumingMemoryBound(to: CInterop.Char.self))
    }
  }

  /// result is c-string length(no \0), return 0 if buffer is too small
  @_alwaysEmitIntoClient
  static func path(pid: ProcessID, into buffer: UnsafeMutableRawBufferPointer) -> Result<Int32, Errno> {
    assert(buffer.count >= pathInfoMaxSize)
    return SyscallUtilities.valueOrErrno {
      proc_pidpath(pid.rawValue, buffer.baseAddress, numericCast(buffer.count))
    }
  }

  struct ListPIDType {
    @_alwaysEmitIntoClient
    internal init(type: UInt32, typeinfo: UInt32) {
      self.type = type
      self.typeinfo = typeinfo
    }
    @usableFromInline
    let type: UInt32
    @usableFromInline
    let typeinfo: UInt32

    @_alwaysEmitIntoClient
    public static var all: Self { .init(type: UInt32(PROC_ALL_PIDS), typeinfo: 0) }
    @_alwaysEmitIntoClient
    public static func processGroup(_ v: UInt32) -> Self { .init(type: UInt32(PROC_PGRP_ONLY), typeinfo: v) }
    @_alwaysEmitIntoClient
    public static func tty(_ v: UInt32) -> Self { .init(type: UInt32(PROC_TTY_ONLY), typeinfo: v) }
    @_alwaysEmitIntoClient
    public static func uid(_ v: UInt32) -> Self { .init(type: UInt32(PROC_UID_ONLY), typeinfo: v) }
    @_alwaysEmitIntoClient
    public static func ruid(_ v: UInt32) -> Self { .init(type: UInt32(PROC_RUID_ONLY), typeinfo: v) }
    @_alwaysEmitIntoClient
    public static func parentProcessID(_ v: UInt32) -> Self { .init(type: UInt32(PROC_PPID_ONLY), typeinfo: v) }
    @_alwaysEmitIntoClient
    public static func kdbg(_ v: UInt32) -> Self { .init(type: UInt32(PROC_KDBG_ONLY), typeinfo: v) }
  }

  @_alwaysEmitIntoClient
  static func listPIDs(_ type: ListPIDType) throws -> [ProcessID] {
    try SyscallUtilities.preallocateSyscall { Proc.listPIDs(type, mode: $0) }.get()
  }

  /// return buffer size
  @_alwaysEmitIntoClient
  static func listPIDs(_ type: ListPIDType, mode: SyscallUtilities.PreAllocateCallMode) -> Result<Int32, Errno> {
    let buffer = mode.toC
    return SyscallUtilities.valueOrErrno {
      proc_listpids(type.type, type.typeinfo, buffer.baseAddress, Int32(buffer.count))
    }
  }

  struct PIDFDInfoType: RawRepresentable {
    public var rawValue: Int32
    @_alwaysEmitIntoClient
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var vnodeInfo: Self { .init(rawValue: PROC_PIDFDVNODEINFO) }
    @_alwaysEmitIntoClient
    public static var vnodePathInfo: Self { .init(rawValue: PROC_PIDFDVNODEPATHINFO) }
    @_alwaysEmitIntoClient
    public static var fdSocketInfo: Self { .init(rawValue: PROC_PIDFDSOCKETINFO) }
    @_alwaysEmitIntoClient
    public static var fdPsemInfo: Self { .init(rawValue: PROC_PIDFDPSEMINFO) }
    @_alwaysEmitIntoClient
    public static var fdPshmInfo: Self { .init(rawValue: PROC_PIDFDPSHMINFO) }
    @_alwaysEmitIntoClient
    public static var fdPipeInfo: Self { .init(rawValue: PROC_PIDFDPIPEINFO) }
    @_alwaysEmitIntoClient
    public static var fdKqueueInfo: Self { .init(rawValue: PROC_PIDFDKQUEUEINFO) }
    @_alwaysEmitIntoClient
    public static var fdChannelInfo: Self { .init(rawValue: PROC_PIDFDCHANNELINFO) }
  }

  /// success when value > 0
  @_alwaysEmitIntoClient
  private static func bufferSizeOrErrno(_ body: () -> Int32) -> Result<Int32, Errno> {
    let v = body()
    if v > 0 {
      return .success(v)
    } else {
      return .failure(.systemCurrent)
    }
  }

  @_alwaysEmitIntoClient
  static func fdInfo<R>(pid: ProcessID, fd: FileDescriptor, type: PIDFDInfoType, into info: inout R) -> Result<Int32, Errno> {
    bufferSizeOrErrno {
      withUnsafeMutableBytes(of: &info) { buffer in
        proc_pidfdinfo(pid.rawValue, fd.rawValue, type.rawValue, buffer.baseAddress, Int32(buffer.count))
      }
    }
  }

  @_alwaysEmitIntoClient
  static func vnodeInfo(pid: ProcessID, fd: FileDescriptor, into info: inout VnodeFDInfo) -> Result<Int32, Errno> {
    fdInfo(pid: pid, fd: fd, type: .vnodeInfo, into: &info)
  }

  @_alwaysEmitIntoClient
  static func vnodeInfoWithPath(pid: ProcessID, fd: FileDescriptor, into info: inout VnodeFDInfoWithPath) -> Result<Int32, Errno> {
    fdInfo(pid: pid, fd: fd, type: .vnodePathInfo, into: &info)
  }

  struct PIDInfoType: RawRepresentable {
    public var rawValue: Int32
    @_alwaysEmitIntoClient
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
    /*

     public var PROC_PIDTASKALLINFO: Int32 { get }

     public var PROC_PIDTBSDINFO: Int32 { get }

     public var PROC_PIDTASKINFO: Int32 { get }

     public var PROC_PIDTHREADINFO: Int32 { get }

     public var PROC_PIDLISTTHREADS: Int32 { get }

     public var PROC_PIDREGIONINFO: Int32 { get }

     public var PROC_PIDREGIONPATHINFO: Int32 { get }

     public var PROC_PIDVNODEPATHINFO: Int32 { get }

     public var PROC_PIDTHREADPATHINFO: Int32 { get }

     public var PROC_PIDPATHINFO: Int32 { get }
     public var PROC_PIDPATHINFO_SIZE: Int32 { get }

     public var PROC_PIDWORKQUEUEINFO: Int32 { get }

     public var PROC_PIDT_SHORTBSDINFO: Int32 { get }

     public var PROC_PIDLISTFILEPORTS: Int32 { get }

     public var PROC_PIDTHREADID64INFO: Int32 { get }

     public var PROC_PID_RUSAGE: Int32 { get }
     public var PROC_PID_RUSAGE_SIZE: Int32 { get }
     */

    @_alwaysEmitIntoClient
    public static var listFDs: Self { .init(rawValue: PROC_PIDLISTFDS) }
    @_alwaysEmitIntoClient
    public static var taskAllInfo: Self { .init(rawValue: PROC_PIDTASKALLINFO) }
    @_alwaysEmitIntoClient
    public static var bsdInfo: Self { .init(rawValue: PROC_PIDTBSDINFO) }
    @_alwaysEmitIntoClient
    public static var taskInfo: Self { .init(rawValue: PROC_PIDTASKINFO) }
    @_alwaysEmitIntoClient
    public static var bsdShortInfo: Self { .init(rawValue: PROC_PIDT_SHORTBSDINFO) }
    @_alwaysEmitIntoClient
    public static var vnodePathInfo: Self { .init(rawValue: PROC_PIDVNODEPATHINFO) }
  }

  @_alwaysEmitIntoClient
  static func listFDs(pid: ProcessID) -> Result<[FDInfo], Errno> {
    SyscallUtilities.preallocateSyscall { mode in
      let buffer = mode.toC
      return SyscallUtilities.valueOrErrno {
        proc_pidinfo(pid.rawValue, PIDInfoType.listFDs.rawValue, 0, buffer.baseAddress, Int32(buffer.count))
      }
    }
  }

  @_alwaysEmitIntoClient
  static func listFDs(pid: ProcessID, mode: SyscallUtilities.PreAllocateCallMode) -> Result<Int32, Errno> {
    let buffer = mode.toC
    return SyscallUtilities.valueOrErrno {
      proc_pidinfo(pid.rawValue, PIDInfoType.listFDs.rawValue, 0, buffer.baseAddress, Int32(buffer.count))
    }
  }

  @_alwaysEmitIntoClient
  static func taskAllInfo(pid: ProcessID, into info: inout TaskAllInfo) -> Result<Int32, Errno> {
    pidInfo(pid: pid, type: .taskAllInfo, arg: 0, value: &info)
  }

  @_alwaysEmitIntoClient
  static func bsdInfo(pid: ProcessID, into info: inout BSDInfo) -> Result<Int32, Errno> {
    pidInfo(pid: pid, type: .bsdInfo, arg: 0, value: &info)
  }

  @_alwaysEmitIntoClient
  static func taskInfo(pid: ProcessID, into info: inout TaskInfo) -> Result<Int32, Errno> {
    pidInfo(pid: pid, type: .taskInfo, arg: 0, value: &info)
  }

  @_alwaysEmitIntoClient
  static func bsdShortInfo(pid: ProcessID, into info: inout BSDShortInfo) -> Result<Int32, Errno> {
    pidInfo(pid: pid, type: .bsdShortInfo, arg: 0, value: &info)
  }

  @_alwaysEmitIntoClient
  static func vnodePathInfo(pid: ProcessID, into info: inout VnodePathInfo) -> Result<Int32, Errno> {
    pidInfo(pid: pid, type: .vnodePathInfo, arg: 0, value: &info)
  }

  @_alwaysEmitIntoClient
  private static func pidInfo<R>(pid: ProcessID, type: PIDInfoType, arg: UInt64, value: inout R) -> Result<Int32, Errno> {
    bufferSizeOrErrno {
      withUnsafeMutableBytes(of: &value) { buffer in
        proc_pidinfo(pid.rawValue, type.rawValue, arg, buffer.baseAddress, Int32(buffer.count))
      }
    }
  }

}

#endif

import SystemLibc
import SystemPackage

public extension FileDescriptor {
  @inlinable @inline(__always)
  func sync() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.fsync(rawValue)
    }
  }
}

public enum FileControl { }

public extension FileControl {

  @inlinable @inline(__always)
  static func control(_ fd: FileDescriptor, command: Command) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      fcntl(fd.rawValue, command.rawValue)
    }
  }

  @inlinable @inline(__always)
  static func control(_ fd: FileDescriptor, command: Command, value: Int32) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      fcntl(fd.rawValue, command.rawValue, value)
    }
  }

  @inlinable @inline(__always)
  static func control(_ fd: FileDescriptor, command: Command, ptr: UnsafeMutableRawPointer) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      fcntl(fd.rawValue, command.rawValue, ptr)
    }
  }

  struct Command: RawRepresentable {
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
    public let rawValue: Int32
  }
}

public extension FileControl.Command {
  @_alwaysEmitIntoClient
  static var duplicateFD: Self { .init(macroValue: F_DUPFD) }
  @_alwaysEmitIntoClient
  static var duplicateFDCloseOnExec: Self { .init(macroValue: F_DUPFD_CLOEXEC) }
  @_alwaysEmitIntoClient
  static var getFlags: Self { .init(macroValue: F_GETFD) }
  @_alwaysEmitIntoClient
  static var setFlags: Self { .init(macroValue: F_SETFD) }
  static var getStatusFlags: Self { .init(macroValue: F_GETFL) }
  @_alwaysEmitIntoClient
  static var setStatusFlags: Self { .init(macroValue: F_SETFL) }
  @_alwaysEmitIntoClient
  static var getProcessID: Self { .init(macroValue: F_GETOWN) }
  @_alwaysEmitIntoClient
  static var setProcessID: Self { .init(macroValue: F_SETOWN) }

}

public extension FileControl {
  @inlinable @inline(__always)
  static func duplicate(_ fd: FileDescriptor) throws -> FileDescriptor {
    try control(fd, command: .duplicateFD).map(FileDescriptor.init).get()
  }

  @inlinable @inline(__always)
  static func duplicateCloseOnExec(_ fd: FileDescriptor) throws -> FileDescriptor {
    try control(fd, command: .duplicateFDCloseOnExec).map(FileDescriptor.init).get()
  }

  @inlinable @inline(__always)
  static func flags(for fd: FileDescriptor) throws -> Int32 {
    try control(fd, command: .getFlags).get()
  }

  @inlinable @inline(__always)
  static func set(_ fd: FileDescriptor, flags: Int32) throws {
    _ = try control(fd, command: .setFlags, value: flags).get()
  }

  @inlinable @inline(__always)
  static func statusFlags(for fd: FileDescriptor) throws -> Int32 {
    try control(fd, command: .getStatusFlags).get()
  }

  @inlinable @inline(__always)
  static func set(_ fd: FileDescriptor, statusFlags: Int32) throws {
    _ = try control(fd, command: .setStatusFlags, value: statusFlags).get()
  }

  @inlinable @inline(__always)
  static func processID(for fd: FileDescriptor) throws -> WaitPID.PID {
    try control(fd, command: .getProcessID).map(WaitPID.PID.init).get()
  }

  @inlinable @inline(__always)
  static func set(_ fd: FileDescriptor, processID: WaitPID.PID) throws {
    _ = try control(fd, command: .setProcessID, value: processID.rawValue).get()
  }

}

#if canImport(Darwin)
public extension FileControl.Command {
  @_alwaysEmitIntoClient
  static var getPath: Self { .init(macroValue: F_GETPATH) }
  @_alwaysEmitIntoClient
  static var getNonFirmlinkedPath: Self { .init(macroValue: F_GETPATH_NOFIRMLINK) }
  @_alwaysEmitIntoClient
  static var preAllocate: Self { .init(macroValue: F_PREALLOCATE) }
  @_alwaysEmitIntoClient
  static var punchHole: Self { .init(macroValue: F_PUNCHHOLE) }
  @_alwaysEmitIntoClient
  static var setSize: Self { .init(macroValue: F_SETSIZE) }
  @_alwaysEmitIntoClient
  static var readAdvisory: Self { .init(macroValue: F_RDADVISE) }
  @_alwaysEmitIntoClient
  static var readAhead: Self { .init(macroValue: F_RDAHEAD) }
  @_alwaysEmitIntoClient
  static var noCache: Self { .init(macroValue: F_NOCACHE) }
  @_alwaysEmitIntoClient
  static var diskDeviceInformation: Self { .init(macroValue: F_LOG2PHYS) }
  @_alwaysEmitIntoClient
  static var diskDeviceInformationExtended: Self { .init(macroValue: F_LOG2PHYS_EXT) }
  @_alwaysEmitIntoClient
  static var barrierFsync: Self { .init(macroValue: F_BARRIERFSYNC) }
  @_alwaysEmitIntoClient
  static var fullSync: Self { .init(macroValue: F_FULLFSYNC) }
  @_alwaysEmitIntoClient
  static var setNoSigPipe: Self { .init(macroValue: F_SETNOSIGPIPE) }
  @_alwaysEmitIntoClient
  static var getNoSigPipe: Self { .init(macroValue: F_GETNOSIGPIPE) }
  @_alwaysEmitIntoClient
  static var transferExtraSpace: Self { .init(macroValue: F_TRANSFEREXTENTS) }
}

public extension FileControl {

  static func path(for fd: FileDescriptor) throws -> String {
    try String(capacity: Int(MAXPATHLEN)) { ptr in
      _ = try control(fd, command: .getPath, ptr: ptr).get()
      return strlen(ptr)
    }
  }

  static func nonFirmlinkedPath(for fd: FileDescriptor) throws -> String {
    try String(capacity: Int(MAXPATHLEN)) { ptr in
      _ = try control(fd, command: .getNonFirmlinkedPath, ptr: ptr).get()
      return strlen(ptr)
    }
  }

  @inlinable @inline(__always)
  static func preAllocate(_ fd: FileDescriptor, options: inout PreAllocateOptions) throws {
    _ = try control(fd, command: .preAllocate, ptr: &options).get()
  }

  struct PreAllocateOptions {
    @usableFromInline
    internal var rawValue: fstore

    public init() {
      rawValue = .init()
    }

    @inlinable @inline(__always)
    public var flags: Flags {
      get {
        .init(rawValue: rawValue.fst_flags)
      }
      set {
        rawValue.fst_flags = newValue.rawValue
      }
    }
    public struct Flags: OptionSet {
      public var rawValue: UInt32
      public init(rawValue: UInt32) {
        self.rawValue = rawValue
      }

      @_alwaysEmitIntoClient
      public static var contiguous: Self { .init(macroValue: F_ALLOCATECONTIG) }
      @_alwaysEmitIntoClient
      public static var all: Self { .init(macroValue: F_ALLOCATEALL) }
    }

    @inlinable @inline(__always)
    public var positionMode: PositionMode {
      get {
        .init(rawValue: rawValue.fst_posmode)
      }
      set {
        rawValue.fst_posmode = newValue.rawValue
      }
    }
    public struct PositionMode: RawRepresentable {
      public let rawValue: Int32
      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      @_alwaysEmitIntoClient
      public static var endOfFile: Self { .init(macroValue: F_PEOFPOSMODE) }
      @_alwaysEmitIntoClient
      public static var volume: Self { .init(macroValue: F_VOLPOSMODE) }
    }

    @inlinable @inline(__always)
    public var offset: Int64 {
      get {
        rawValue.fst_offset
      }
      set {
        rawValue.fst_offset = newValue
      }
    }

    @inlinable @inline(__always)
    public var length: Int64 {
      get {
        rawValue.fst_length
      }
      set {
        rawValue.fst_length = newValue
      }
    }

    @inlinable @inline(__always)
    public var allocatedBytes: Int64 {
      rawValue.fst_bytesalloc
    }
  }
}
#endif

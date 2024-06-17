import SystemLibc
import SystemPackage
import CUtility

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

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func control(_ fd: FileDescriptor, command: Command) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      fcntl(fd.rawValue, command.rawValue)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func control(_ fd: FileDescriptor, command: Command, value: Int32) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      fcntl(fd.rawValue, command.rawValue, value)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func control(_ fd: FileDescriptor, command: Command, ptr: UnsafeMutableRawPointer) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      fcntl(fd.rawValue, command.rawValue, ptr)
    }
  }

  struct Command: MacroRawRepresentable {
    @_alwaysEmitIntoClient @inlinable @inline(__always)
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
  @_alwaysEmitIntoClient
  static var getStatusFlags: Self { .init(macroValue: F_GETFL) }
  @_alwaysEmitIntoClient
  static var setStatusFlags: Self { .init(macroValue: F_SETFL) }
  @_alwaysEmitIntoClient
  static var getProcessID: Self { .init(macroValue: F_GETOWN) }
  @_alwaysEmitIntoClient
  static var setProcessID: Self { .init(macroValue: F_SETOWN) }

}

public extension FileControl {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func duplicate(_ fd: FileDescriptor) throws -> FileDescriptor {
    try control(fd, command: .duplicateFD).map(FileDescriptor.init).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func duplicateCloseOnExec(_ fd: FileDescriptor) throws -> FileDescriptor {
    try control(fd, command: .duplicateFDCloseOnExec).map(FileDescriptor.init).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func flags(for fd: FileDescriptor) throws -> FileDescriptorFlags {
    try .init(rawValue: control(fd, command: .getFlags).get())
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(_ fd: FileDescriptor, flags: FileDescriptorFlags) throws {
    _ = try control(fd, command: .setFlags, value: flags.rawValue).get()
  }

  struct FileDescriptorFlags: OptionSet, MacroRawRepresentable {
    public var rawValue: Int32
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var closeOnExec: Self { .init(macroValue: FD_CLOEXEC) }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func statusFlags(for fd: FileDescriptor) throws -> Int32 {
    try control(fd, command: .getStatusFlags).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(_ fd: FileDescriptor, statusFlags: Int32) throws {
    _ = try control(fd, command: .setStatusFlags, value: statusFlags).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func processID(for fd: FileDescriptor) throws -> ProcessID {
    try control(fd, command: .getProcessID).map(ProcessID.init).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(_ fd: FileDescriptor, processID: ProcessID) throws {
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
    try String(bytesCapacity: Int(MAXPATHLEN)) { buffer in
      _ = try control(fd, command: .getPath, ptr: buffer.baseAddress!).get()
      return strlen(buffer.baseAddress!)
    }
  }

  static func nonFirmlinkedPath(for fd: FileDescriptor) throws -> String {
    try String(bytesCapacity: Int(MAXPATHLEN)) { buffer in
      _ = try control(fd, command: .getNonFirmlinkedPath, ptr: buffer.baseAddress!).get()
      return strlen(buffer.baseAddress!)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func preAllocate(_ fd: FileDescriptor, options: inout PreAllocateOptions) throws {
    _ = try control(fd, command: .preAllocate, ptr: &options).get()
  }

  struct PreAllocateOptions {
    @usableFromInline
    internal var rawValue: fstore

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() {
      rawValue = .init()
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var flags: Flags {
      get {
        .init(rawValue: rawValue.fst_flags)
      }
      set {
        rawValue.fst_flags = newValue.rawValue
      }
    }
    public struct Flags: OptionSet, MacroRawRepresentable {
      public var rawValue: UInt32
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: UInt32) {
        self.rawValue = rawValue
      }

      /// Allocate contiguous space. (Note that the file system may ignore this request if length is very large.)
      @_alwaysEmitIntoClient
      public static var contiguous: Self { .init(macroValue: F_ALLOCATECONTIG) }
      /// Allocate all requested space or no space at all.
      @_alwaysEmitIntoClient
      public static var all: Self { .init(macroValue: F_ALLOCATEALL) }
      /// Allocate space that is not freed when close(2) is called. (Note that the file system may ignore this request.)
      @_alwaysEmitIntoClient
      public static var persist: Self { .init(macroValue: F_ALLOCATEPERSIST) }
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var positionMode: PositionMode {
      get { .init(rawValue: rawValue.fst_posmode) }
      set { rawValue.fst_posmode = newValue.rawValue }
    }
    public struct PositionMode: MacroRawRepresentable {
      public let rawValue: Int32
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      /// Allocate from the physical end of file.  In this case, fst_length indicates the number of newly allocated bytes desired.
      @_alwaysEmitIntoClient
      public static var endOfFile: Self { .init(macroValue: F_PEOFPOSMODE) }
      /// Allocate from the volume offset.
      @_alwaysEmitIntoClient
      public static var volume: Self { .init(macroValue: F_VOLPOSMODE) }
    }

    /// start of the region
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var offset: Int64 {
      _read { yield rawValue.fst_offset }
      _modify { yield &rawValue.fst_offset }
    }

    /// size of the region
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var length: Int64 {
      _read { yield rawValue.fst_length }
      _modify { yield &rawValue.fst_length }
    }

    /// number of bytes allocated
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var allocatedBytes: Int64 {
      rawValue.fst_bytesalloc
    }
  }
}
#endif

#if os(Linux)
public extension FileControl {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func posixFileAllocate(_ fd: FileDescriptor, offset: Int, length: Int) throws {
    try SyscallUtilities.errnoOrZeroOnReturn {
      SystemLibc.posix_fallocate(fd.rawValue, offset, length)
    }.get()
  }
}
#endif

#if os(Linux)
public extension FileControl {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func _linuxFileAllocate(_ fd: FileDescriptor, mode: Int32, offset: Int, length: Int) throws {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.fallocate(fd.rawValue, mode, offset, length)
    }.get()
  }
}
#endif

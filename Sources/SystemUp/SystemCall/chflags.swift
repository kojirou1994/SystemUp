#if canImport(Darwin)
import CUtility
import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(flags: FileFlags, for path: borrowing some CString) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      path.withUnsafeCString { path in
        SystemLibc.chflags(path, flags.rawValue)
      }
    }.get()
  }
  
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(flags: FileFlags, for fd: FileDescriptor) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.fchflags(fd.rawValue, flags.rawValue)
    }.get()
  }

  struct FileFlags: OptionSet, MacroRawRepresentable {

    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    public let rawValue: UInt32

    /// Do not dump the file.
    @_alwaysEmitIntoClient
    public static var userNoDump: Self { .init(macroValue: UF_NODUMP) }

    /// The file may not be changed.
    @_alwaysEmitIntoClient
    public static var userImmutable: Self { .init(macroValue: UF_IMMUTABLE) }

    /// The file may only be appended to.
    @_alwaysEmitIntoClient
    public static var userAppend: Self { .init(macroValue: UF_APPEND) }

    /// The directory is opaque when viewed through a union stack.
    @_alwaysEmitIntoClient
    public static var userOpaque: Self { .init(macroValue: UF_OPAQUE) }

    /// The file or directory is not intended to be displayed to the user.
    @_alwaysEmitIntoClient
    public static var userHidden: Self { .init(macroValue: UF_HIDDEN) }

    /// The file has been archived.
    @_alwaysEmitIntoClient
    public static var superArchived: Self { .init(macroValue: SF_ARCHIVED) }

    /// The file may not be changed.
    @_alwaysEmitIntoClient
    public static var superImmutable: Self { .init(macroValue: SF_IMMUTABLE) }

    /// The file may only be appended to.
    @_alwaysEmitIntoClient
    public static var superAppend: Self { .init(macroValue: SF_APPEND) }

    /// The file is a dataless placeholder.  The system will attempt to materialize it when accessed according to the dataless file materialization policy of the accessing thread or process.  See getiopolicy_np(3).
    @_alwaysEmitIntoClient
    public static var superDataless: Self { .init(macroValue: SF_DATALESS) }

  }
}
#endif // chflags end

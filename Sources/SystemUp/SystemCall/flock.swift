import CUtility
import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func lock(_ fd: FileDescriptor, flags: LockFlags) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      flock(fd.rawValue, flags.rawValue)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func unlock(_ fd: FileDescriptor) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      flock(fd.rawValue, LOCK_UN)
    }
  }

  struct LockFlags: OptionSet, MacroRawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// shared lock
    @_alwaysEmitIntoClient
    public static var shared: Self { .init(macroValue: LOCK_SH) }

    /// exclusive lock
    @_alwaysEmitIntoClient
    public static var exclusive: Self { .init(macroValue: LOCK_EX) }

    /// don't block when locking
    @_alwaysEmitIntoClient
    public static var noBlock: Self { .init(macroValue: LOCK_NB) }

  }
}

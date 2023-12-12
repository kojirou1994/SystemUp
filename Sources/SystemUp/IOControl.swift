import SystemLibc
import SystemPackage
import CUtility

public enum IOControl { }

public extension IOControl {

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static func control(_ fd: FileDescriptor, request: Request) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      ioctl(fd.rawValue, request.rawValue)
    }
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static func control(_ fd: FileDescriptor, request: Request, value: Int32) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      ioctl(fd.rawValue, request.rawValue, value)
    }
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static func control(_ fd: FileDescriptor, request: Request, ptr: UnsafeMutableRawPointer) -> Result<Int32, Errno> {
    SyscallUtilities.valueOrErrno {
      ioctl(fd.rawValue, request.rawValue, ptr)
    }
  }

  struct Request: RawRepresentable {
    public init(rawValue: UInt) {
      self.rawValue = rawValue
    }
    public let rawValue: UInt
  }
}

public extension IOControl.Request {
  @_alwaysEmitIntoClient
  static var setCloseOnExec: Self { .init(rawValue: swift_FIOCLEX()) }
  @_alwaysEmitIntoClient
  static var removeCloseOnExec: Self { .init(rawValue: swift_FIONCLEX()) }
  @_alwaysEmitIntoClient
  static var getBytesToRead: Self { .init(rawValue: swift_FIONREAD()) }
  @_alwaysEmitIntoClient
  static var setOrClearNonBlockingIO: Self { .init(rawValue: swift_FIONBIO()) }
  @_alwaysEmitIntoClient
  static var setOrClearAsyncIO: Self { .init(rawValue: swift_FIOASYNC()) }
}

#if canImport(Darwin)
public extension IOControl.Request {
  @_alwaysEmitIntoClient
  static var setOwner: Self { .init(rawValue: swift_FIOSETOWN()) }
  @_alwaysEmitIntoClient
  static var getOwner: Self { .init(rawValue: swift_FIOGETOWN()) }
  @_alwaysEmitIntoClient
  static var getDType: Self { .init(rawValue: swift_FIODTYPE()) }
}
#endif

import CUtility
import SystemLibc

public extension SystemCall {

  /// reposition read/write file offset
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func seek(_ fd: FileDescriptor, offset: Int64, from whence: SeekOrigin) throws(Errno) -> Int64 {
    try Int64(SyscallUtilities.valueOrErrno {
      SystemLibc.lseek(fd.rawValue, numericCast(offset), whence.rawValue)
    }.get())
  }

  struct SeekOrigin: RawRepresentable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    public static var start: Self { .init(rawValue: SEEK_SET) }

    @_alwaysEmitIntoClient
    public static var current: Self { .init(rawValue: SEEK_CUR) }

    @_alwaysEmitIntoClient
    public static var end: Self { .init(rawValue: SEEK_END) }

    #if UNIX_BSD

    @_alwaysEmitIntoClient
    public static var nextHole: Self { .init(rawValue: SEEK_HOLE) }

    @_alwaysEmitIntoClient
    public static var nextData: Self { .init(rawValue: SEEK_DATA) }

    #endif

  }

}

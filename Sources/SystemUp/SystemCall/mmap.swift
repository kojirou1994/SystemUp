#if APPLE
import SystemLibc
import CUtility

public extension SystemCall {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func mmap(address: UnsafeMutableRawPointer? = nil, length: Int, accessibility: MMAPAccessibility, flags: MMAPFlags, fd: FileDescriptor, offset: Int64) throws(Errno) -> UnsafeMutableRawPointer {
    let result = SystemLibc.mmap(address, length, accessibility.rawValue, flags.rawValue, fd.rawValue, numericCast(offset))
    if result == SystemLibc.MAP_FAILED {
      throw Errno.systemCurrent
    }
    return result!
  }
  
  /// remove a mapping
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func munmap(address: UnsafeMutableRawPointer, length: Int) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.munmap(address, length)
    }.get()
  }

  /// synchronize a mapped region
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func msync(address: UnsafeMutableRawPointer, length: Int, flags: MMAPSyncFlags) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.msync(address, length, flags.rawValue)
    }.get()
  }

  struct MMAPAccessibility: OptionSet {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// Pages may not be accessed.
    @_alwaysEmitIntoClient
    public static var none: Self { .init(rawValue: PROT_NONE) }
    /// Pages may be read.
    @_alwaysEmitIntoClient
    public static var read: Self { .init(rawValue: PROT_READ) }
    /// Pages may be written.
    @_alwaysEmitIntoClient
    public static var write: Self { .init(rawValue: PROT_WRITE) }
    /// Pages may be executed.
    @_alwaysEmitIntoClient
    public static var exec: Self { .init(rawValue: PROT_EXEC) }
  }

  struct MMAPFlags: OptionSet {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    @_alwaysEmitIntoClient
    public static var anonymous: Self { .init(rawValue: MAP_ANON) }
    @_alwaysEmitIntoClient
    public static var file: Self { .init(rawValue: MAP_FILE) }
    @_alwaysEmitIntoClient
    public static var fixed: Self { .init(rawValue: MAP_FIXED) }
    /// Notify the kernel that the region may contain semaphores and that special handling may be necessary.
    @_alwaysEmitIntoClient
    public static var hasSemaphore: Self { .init(rawValue: MAP_HASSEMAPHORE) }
    /// Modifications are private (copy-on-write).
    @_alwaysEmitIntoClient
    public static var `private`: Self { .init(rawValue: MAP_PRIVATE) }
    /// Modifications are shared.
    @_alwaysEmitIntoClient
    public static var shared: Self { .init(rawValue: MAP_SHARED) }
    @_alwaysEmitIntoClient
    public static var noCache: Self { .init(rawValue: MAP_NOCACHE) }
    @_alwaysEmitIntoClient
    public static var hit: Self { .init(rawValue: MAP_JIT) }
    @_alwaysEmitIntoClient
    public static var `32bit`: Self { .init(rawValue: MAP_32BIT) }
  }

  struct MMAPSyncFlags: RawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32
    
    /// Return immediately
    @_alwaysEmitIntoClient
    public static var `async`: Self { .init(rawValue: MS_ASYNC) }
    /// Perform synchronous writes
    @_alwaysEmitIntoClient
    public static var sync: Self { .init(rawValue: MS_SYNC) }
    /// Invalidate all cached data
    @_alwaysEmitIntoClient
    public static var invalidate: Self { .init(rawValue: MS_INVALIDATE) }
  }
}
#endif

import SystemLibc
import CUtility

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func madvise(_ ptr: UnsafeMutableRawPointer, length: Int, advise: MemoryAdvise) throws(Errno) {
    SystemLibc.madvise(ptr, length, advise.rawValue)
  }

  struct MemoryAdvise: OptionSet {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    @_alwaysEmitIntoClient
    public static var normal: Self { .init(rawValue: MADV_NORMAL) }
    @_alwaysEmitIntoClient
    public static var sequential: Self { .init(rawValue: MADV_SEQUENTIAL) }
    @_alwaysEmitIntoClient
    public static var random: Self { .init(rawValue: MADV_RANDOM) }
    @_alwaysEmitIntoClient
    public static var willNeed: Self { .init(rawValue: MADV_WILLNEED) }
    @_alwaysEmitIntoClient
    public static var dontNeed: Self { .init(rawValue: MADV_DONTNEED) }
    @_alwaysEmitIntoClient
    public static var free: Self { .init(rawValue: MADV_FREE) }
    @_alwaysEmitIntoClient
    public static var zeroWiredPages: Self { .init(rawValue: MADV_ZERO_WIRED_PAGES) }
    @_alwaysEmitIntoClient
    public static var zero: Self { .init(rawValue: MADV_ZERO) }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func posixMadvise(_ ptr: UnsafeMutableRawPointer, length: Int, advise: PosixMemoryAdvise) throws(Errno) {
    SystemLibc.posix_madvise(ptr, length, advise.rawValue)
  }

  struct PosixMemoryAdvise: OptionSet {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    @_alwaysEmitIntoClient
    public static var normal: Self { .init(rawValue: POSIX_MADV_NORMAL) }
    @_alwaysEmitIntoClient
    public static var sequential: Self { .init(rawValue: POSIX_MADV_SEQUENTIAL) }
    @_alwaysEmitIntoClient
    public static var random: Self { .init(rawValue: POSIX_MADV_RANDOM) }
    @_alwaysEmitIntoClient
    public static var willNeed: Self { .init(rawValue: POSIX_MADV_WILLNEED) }
    @_alwaysEmitIntoClient
    public static var dontNeed: Self { .init(rawValue: POSIX_MADV_DONTNEED) }
  }
}

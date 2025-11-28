import CUtility
import SystemLibc

public enum SystemCall {
  public struct AtFlags: OptionSet, MacroRawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// Use effective ids in access check
    @_alwaysEmitIntoClient
    public static var effectiveAccess: Self { .init(macroValue: AT_EACCESS) }

    /// Act on the symlink itself not the target
    @_alwaysEmitIntoClient
    public static var noFollow: Self { .init(macroValue: AT_SYMLINK_NOFOLLOW) }

    /// Act on target of symlink
    @_alwaysEmitIntoClient
    public static var follow: Self { .init(macroValue: AT_SYMLINK_FOLLOW) }

    /// Path refers to directory
    @_alwaysEmitIntoClient
    public static var removeDir: Self { .init(macroValue: AT_REMOVEDIR) }

    /// Return real device inodes resides on for fstatat(2)
    #if canImport(Darwin)
    @_alwaysEmitIntoClient
    public static var realDevice: Self { .init(macroValue: AT_REALDEV) }
    #endif

    /// Path should not contain any symlinks
    #if canImport(Darwin) || os(FreeBSD)
    @_alwaysEmitIntoClient
    public static var noFollowAny: Self { .init(macroValue: AT_SYMLINK_NOFOLLOW_ANY) }
    #endif

    /// Use only the fd and Ignore the path for fstatat(2)
    #if canImport(Darwin)
    @_alwaysEmitIntoClient
    public static var fdOnly: Self { .init(macroValue: AT_FDONLY) }
    #endif
  }
}

extension SystemCall {
  public enum RelativeDirectory {
    case cwd
    case directory(FileDescriptor)

    @inlinable @inline(__always)
    var toFD: Int32 {
      switch self {
      case .cwd: return AT_FDCWD
      case .directory(let fd): return fd.rawValue
      }
    }
  }
}

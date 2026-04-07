#if os(Linux)
import SystemLibc
import CUtility

public enum GNULibc {
}

public extension GNULibc {
  @_alwaysEmitIntoClient
  static var version: StaticCString {
    .init(cString: SystemLibc.gnu_get_libc_version())
  }

  @_alwaysEmitIntoClient
  static var release: StaticCString {
    .init(cString: SystemLibc.gnu_get_libc_release())
  }
}
#endif

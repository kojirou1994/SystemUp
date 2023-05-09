#if os(Linux)
import CUtility
import CSystemUp

public enum GNULibc {
}

public extension GNULibc {
  @_alwaysEmitIntoClient
  static var version: StaticCString {
    .init(cString: gnu_get_libc_version())
  }

  @_alwaysEmitIntoClient
  static var release: StaticCString {
    .init(cString: gnu_get_libc_release())
  }
}
#endif

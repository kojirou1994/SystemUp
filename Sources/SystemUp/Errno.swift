import SystemPackage
import SystemLibc
import CUtility

public extension Errno {

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  static var systemCurrent: Self {
    get { .init(rawValue: SystemLibc.errno) }
    set { SystemLibc.errno = newValue.rawValue }
  }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  var errorMessage: StaticCString? {
    SystemLibc.strerror(rawValue).map { .init(cString: $0) }
  }
}

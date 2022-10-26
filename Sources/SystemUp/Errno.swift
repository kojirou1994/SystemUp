import SystemPackage
import SystemLibc
import CUtility

public extension Errno {
  @inlinable @inline(__always)
  static var systemCurrent: Self {
    get {
      .init(rawValue: SystemLibc.errno)
    }
    set {
      SystemLibc.errno = newValue.rawValue
    }
  }

  @inlinable @inline(__always)
  var errorMessage: StaticCString? {
    SystemLibc.strerror(rawValue).map { .init(cString: $0) }
  }
}

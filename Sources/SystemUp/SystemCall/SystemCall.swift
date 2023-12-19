import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public enum SystemCall {}

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

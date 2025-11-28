#if canImport(Darwin)
import MachO

public extension SystemCall {

  /// use _NSGetExecutablePath.
  /// It returns false if the buffer is not large enough, and *size is set to the size required.
  /// buffer is null-terminated if success.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getExecutablePath(buffer: UnsafeMutablePointer<CChar>?, size: inout UInt32) -> Bool {
    switch _NSGetExecutablePath(buffer, &size) {
    case 0: return true
    case -1: return false
    default:
      assertionFailure("Impossible value returned!")
      return false
    }
  }

}
#endif

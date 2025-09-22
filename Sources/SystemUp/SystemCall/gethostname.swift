import SystemPackage
import SystemLibc
import SyscallValue
import CUtility

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func gethostname(into buffer: UnsafeMutableBufferPointer<Int8>) throws(Errno) {
    assert(buffer.count >= sysconf(_SC_HOST_NAME_MAX))
    try SyscallUtilities.voidOrErrno {
      SystemLibc.gethostname(buffer.baseAddress, buffer.count)
    }.get()
  }
}

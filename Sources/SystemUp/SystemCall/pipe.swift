import CUtility
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func pipe() throws(Errno) -> (readEnd: FileDescriptor, writeEnd: FileDescriptor) {
    try withUnsafeTemporaryAllocation(of: Int32.self, capacity: 2) { fds in
      SyscallUtilities.valueOrErrno {
        SystemLibc.pipe(fds.baseAddress.unsafelyUnwrapped)
      }.map { _ in (.init(rawValue: fds[0]), .init(rawValue: fds[1])) }
    }.get()
  }

}

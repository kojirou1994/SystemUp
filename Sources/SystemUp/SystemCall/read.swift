import CUtility
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func read(_ fd: FileDescriptor, into buffer: UnsafeMutableRawBufferPointer) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.read(fd.rawValue, buffer.baseAddress, buffer.count)
    }.get()
  }

}

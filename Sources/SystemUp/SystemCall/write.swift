import CUtility
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func write(_ fd: FileDescriptor, buffer: UnsafeRawBufferPointer) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.write(fd.rawValue, buffer.baseAddress, buffer.count)
    }.get()
  }

}

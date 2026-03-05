import SystemLibc

public extension SystemCall {

  #if APPLE
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func sendfile(from src: FileDescriptor, to dst: FileDescriptor, offset: Int64, bytes: UnsafeMutablePointer<Int64>, hdtr: UnsafeMutableRawPointer? = nil) throws(Errno) {
    // The flags parameter is reserved for future expansion and must be set to 0. Any other value will cause sendfile() to return EINVAL.
    try SyscallUtilities.voidOrErrno {
      SystemLibc.sendfile(src.rawValue, dst.rawValue, offset, bytes, hdtr?.assumingMemoryBound(to: sf_hdtr.self), 0)
    }.get()
  }
  #endif

  #if os(Linux)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func sendfile(from src: FileDescriptor, to dst: FileDescriptor, offset: UnsafeMutablePointer<Int>?, count: Int) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.sendfile(dst.rawValue, src.rawValue, offset, count)
    }.get()
  }
  #endif
}

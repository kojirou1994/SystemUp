import SystemPackage
import SystemLibc
import SyscallValue
import CUtility

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func realPath(_ path: borrowing some CStringConvertible & ~Copyable) throws(Errno) -> DynamicCString {
    try SyscallUtilities.unwrap {
      path.withUnsafeCString { path in
        realpath(path, nil)
      }
    }.map(DynamicCString.init).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func realPath(_ path: borrowing some CStringConvertible & ~Copyable, into buffer: UnsafeMutableBufferPointer<Int8>) throws(Errno) {
    assert(buffer.count >= PATH_MAX)
    let ptr = try SyscallUtilities.unwrap {
      path.withUnsafeCString { path in
        realpath(path, buffer.baseAddress)
      }
    }.get()
    assert(ptr == buffer.baseAddress)
  }
}

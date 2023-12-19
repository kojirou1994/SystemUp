import CUtility
import CGeneric
import SystemPackage
import SystemLibc
import SyscallValue

public extension SystemCall {

  @CStringGeneric
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func realPath(_ path: String) -> Result<UnsafeMutablePointer<Int8>, Errno> {
    SyscallUtilities.unwrap {
      realpath(path, nil)
    }
  }

  @CStringGeneric
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func realPath(_ path: String, into buffer: UnsafeMutableBufferPointer<Int8>) -> Result<Void, Errno> {
    assert(buffer.count >= PATH_MAX)
    return SyscallUtilities.unwrap {
      realpath(path, buffer.baseAddress)
    }
  }
}

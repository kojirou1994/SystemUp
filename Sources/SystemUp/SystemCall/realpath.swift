import CUtility
import CGeneric
import SystemPackage
import SystemLibc
import SyscallValue

public extension SystemCall {

  @CStringGeneric
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func realPath(_ path: String) -> Result<FilePath, Errno> {
    realPath(path).map { path in
      // TODO: avoid path coping
      defer {
        path.deallocate()
      }
      return .init(platformString: path)
    }
  }


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

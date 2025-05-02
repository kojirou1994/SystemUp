import SystemPackage
import SystemLibc
import SyscallValue

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func realPath(_ path: UnsafePointer<CChar>) -> Result<FilePath, Errno> {
    realPath(path).map { path in
      // TODO: avoid path coping
      defer {
        path.deallocate()
      }
      return .init(platformString: path)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func realPath(_ path: UnsafePointer<CChar>) -> Result<UnsafeMutablePointer<Int8>, Errno> {
    SyscallUtilities.unwrap {
      realpath(path, nil)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func realPath(_ path: UnsafePointer<CChar>, into buffer: UnsafeMutableBufferPointer<Int8>) -> Result<Void, Errno> {
    assert(buffer.count >= PATH_MAX)
    return SyscallUtilities.unwrap {
      realpath(path, buffer.baseAddress)
    }
  }
}

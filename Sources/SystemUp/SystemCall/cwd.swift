import SystemPackage
import SystemLibc
import CGeneric
import CUtility

public extension SystemCall {

  /// get  working directory path
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getWorkingDirectory() -> Result<FilePath, Errno> {
    getWorkingDirectoryBuffer().map { path in
      // TODO: avoid path coping
      defer {
        path.deallocate()
      }
      return .init(platformString: path)
    }
  }

  /// get  working directory path buffer, buffer needs to be released.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getWorkingDirectoryBuffer() -> Result<UnsafeMutablePointer<Int8>, Errno> {
    SyscallUtilities.unwrap {
      SystemLibc.getcwd(nil, 0)
    }
  }

  /// copies the absolute pathname of the current working directory into the buffer, including the terminating null byte
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func readWorkingDirectory(into buffer: UnsafeMutableBufferPointer<Int8>) -> Result<Void, Errno> {
    assert(!buffer.isEmpty, "invalid buffer!")
    return SyscallUtilities.unwrap {
      SystemLibc.getcwd(buffer.baseAddress, buffer.count)
    }
  }

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func changeWorkingDirectory(_ path: String) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.chdir(path)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func changeWorkingDirectory(_ fd: FileDescriptor) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.fchdir(fd.rawValue)
    }
  }
}

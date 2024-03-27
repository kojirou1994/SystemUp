import CUtility
import CGeneric
import SystemPackage
import SystemLibc
import SyscallValue

public extension SystemCall {

  #if canImport(Darwin)
  @available(macOS 13.0, macCatalyst 16.0, *)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func readLink(_ fd: FileDescriptor, into buffer: UnsafeMutableBufferPointer<Int8>) -> Result<Int, Errno> {
    SyscallUtilities.valueOrErrno {
      freadlink(fd.rawValue, buffer.baseAddress, buffer.count)
    }
  }
  #endif

  /// read value of a symbolic link
  /// - Parameters:
  ///   - path: path
  ///   - base: path base
  ///   - buffer: destination buffer
  /// - Returns: count of bytes placed in the buffer, readlink() does not append a null byte
  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func readLink(_ path: String, relativeTo base: RelativeDirectory = .cwd, into buffer: UnsafeMutableBufferPointer<Int8>) -> Result<Int, Errno> {
    SyscallUtilities.valueOrErrno {
      readlinkat(base.toFD, path, buffer.baseAddress!, buffer.count)
    }
  }
}

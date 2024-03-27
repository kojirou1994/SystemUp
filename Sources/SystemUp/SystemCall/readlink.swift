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

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func readLink(_ path: String, relativeTo base: RelativeDirectory = .cwd) -> Result<FilePath, Errno> {

    var bufsize = 256
    var buffer = UnsafeMutableBufferPointer<Int8>.allocate(capacity: bufsize)
    defer {
      buffer.deallocate()
    }

    while true {

      switch readLink(path, relativeTo: base, into: buffer) {
      case .failure(let err): return .failure(err)
      case .success(let length):
        if length != bufsize {
          buffer[length] = 0
          return .success(.init(platformString: buffer.baseAddress.unsafelyUnwrapped))
        }

        bufsize = bufsize * 2
        buffer = .init(start: realloc(buffer.baseAddress, bufsize).assumingMemoryBound(to: Int8.self), count: bufsize)
      }
    }
  }

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

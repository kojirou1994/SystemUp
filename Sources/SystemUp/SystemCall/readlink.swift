import SystemLibc
import SyscallValue
import CUtility

public extension SystemCall {

  #if APPLE
  @available(macOS 13.0, macCatalyst 16.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func readLink(_ fd: FileDescriptor, into buffer: UnsafeMutableBufferPointer<Int8>) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      freadlink(fd.rawValue, buffer.baseAddress, buffer.count)
    }.get()
  }
  #endif

  /// ref: https://github.com/rust-lang/rust/blob/622ac043764d5d4ffff8de8cf86a1cc938a8a71b/library/std/src/sys/fs/unix.rs#L1849
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func readLink(_ path: borrowing some CString, relativeTo base: RelativeDirectory = .cwd) throws -> DynamicCStringWithLength {

    var bufsize = 256

    var buffer = try Memory.allocate(of: Int8.self, capacity: bufsize)

    while true {
      do {
        let length = try readLink(path, relativeTo: base, into: buffer)
        if length != bufsize {
          buffer[length] = 0
          return .init(cString: .init(cString: buffer.baseAddress!), forceLength: length)
        }

        bufsize = bufsize * 2
        try Memory.resize(&buffer, capacity: bufsize)
      } catch {
        Memory.free(buffer.baseAddress)
        throw error
      }
    }
  }

  /// read value of a symbolic link
  /// - Parameters:
  ///   - path: path
  ///   - base: path base
  ///   - buffer: destination buffer
  /// - Returns: count of bytes placed in the buffer, readlink() does not append a null byte
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func readLink(_ path: borrowing some CString, relativeTo base: RelativeDirectory = .cwd, into buffer: UnsafeMutableBufferPointer<Int8>) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      path.withUnsafeCString { path in
        readlinkat(base.toFD, path, buffer.baseAddress!, buffer.count)
      }
    }.get()
  }
}

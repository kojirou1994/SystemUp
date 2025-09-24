import SystemPackage
import SystemLibc
import CUtility

public extension SystemCall {

  /// get  working directory path
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getWorkingDirectory() throws(Errno) -> FilePath {
    // TODO: avoid path coping
    try getWorkingDirectoryBuffer().withUnsafeCString { path in
      FilePath(platformString: path)
    }
  }

  /// get  working directory path buffer, buffer needs to be released.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getWorkingDirectoryBuffer() throws(Errno) -> DynamicCString {
    .init(cString: try SyscallUtilities.unwrap {
      SystemLibc.getcwd(nil, 0)
    }.get())
  }

  /// copies the absolute pathname of the current working directory into the buffer, including the terminating null byte
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func readWorkingDirectory(into buffer: UnsafeMutableBufferPointer<Int8>) throws(Errno) {
    assert(!buffer.isEmpty, "invalid buffer!")
    _ = try SyscallUtilities.unwrap {
      SystemLibc.getcwd(buffer.baseAddress, buffer.count)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func changeWorkingDirectory(_ path: borrowing some CString) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      path.withUnsafeCString { path in
        SystemLibc.chdir(path)
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func changeWorkingDirectory(_ fd: FileDescriptor) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.fchdir(fd.rawValue)
    }.get()
  }
}

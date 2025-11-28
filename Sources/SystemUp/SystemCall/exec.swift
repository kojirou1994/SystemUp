#if os(macOS) || os(iOS) || os(freeBSD) || os(Linux)
import SystemLibc
import CUtility

public extension SystemCall {

  /// generic exec helper
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exec(_ executablePath: borrowing some CString, arguments: some Collection<some ContiguousUTF8Bytes>, searchPATH: Bool) throws(Errno) -> Never {
    assert(arguments.first(where: { _ in true }) != nil, "The first argument, by convention, should point to the file name associated with the file being executed.")

    try withTempUnsafeCStringArray(arguments) { argv throws(Errno) in
      try exec(executablePath, argv: argv, searchPATH: searchPATH)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exec(_ executablePath: borrowing some CString, argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, envp: UnsafePointer<UnsafeMutablePointer<CChar>?>?) throws(Errno) -> Never {
    try SyscallUtilities.voidOrErrno {
      // __envp must be non-nil
      executablePath.withUnsafeCString { executablePath in
        if let envp {
          return execve(executablePath, argv, envp)
        } else {
          // empty environment
          var termination: UnsafeMutablePointer<CChar>?
          return execve(executablePath, argv, &termination)
        }
      }
    }.get()
    fatalError()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exec(_ executablePath: borrowing some CString, argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, searchPATH: Bool) throws(Errno) -> Never {
    try SyscallUtilities.voidOrErrno {
      executablePath.withUnsafeCString { executablePath in
        searchPATH ? execvp(executablePath, argv) : execv(executablePath, argv)
      }
    }.get()
    fatalError()
  }

#if os(macOS) || os(FreeBSD)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exec(_ executablePath: borrowing some CString, argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, withPATH path: UnsafePointer<CChar>) throws(Errno) -> Never {
    // searchpath must be non-nil
    try SyscallUtilities.voidOrErrno {
      executablePath.withUnsafeCString { executablePath in
        execvP(executablePath, path, argv)
      }
    }.get()
    fatalError()
  }
#endif

}
#endif

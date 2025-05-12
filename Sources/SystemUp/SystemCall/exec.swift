#if os(macOS) || os(iOS) || os(freeBSD) || os(Linux)
import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exec(_ executablePath: UnsafePointer<CChar>, argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, envp: UnsafePointer<UnsafeMutablePointer<CChar>?>?) throws(Errno) -> Never {
    try SyscallUtilities.voidOrErrno {
      // __envp must be non-nil
      if let envp {
        return execve(executablePath, argv, envp)
      } else {
        // empty environment
        var termination: UnsafeMutablePointer<CChar>?
        return execve(executablePath, argv, &termination)
      }
    }.get()
    fatalError()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exec(_ executablePath: UnsafePointer<CChar>, argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, searchPATH: Bool) throws(Errno) -> Never {
    try SyscallUtilities.voidOrErrno {
      searchPATH ? execvp(executablePath, argv) : execv(executablePath, argv)
    }.get()
    fatalError()
  }

#if os(macOS) || os(FreeBSD)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exec(_ executablePath: UnsafePointer<CChar>, argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, withPATH path: UnsafePointer<CChar>) throws(Errno) -> Never {
    // searchpath must be non-nil
    try SyscallUtilities.voidOrErrno {
      execvP(executablePath, path, argv)
    }.get()
    fatalError()
  }
#endif

}
#endif

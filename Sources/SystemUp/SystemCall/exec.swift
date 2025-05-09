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
  static func exec(_ executablePath: UnsafePointer<CChar>, argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, searchPATH: Bool) throws -> Never {
    try SyscallUtilities.voidOrErrno {
      searchPATH ? execvp(executablePath, argv) : execv(executablePath, argv)
    }.get()
    fatalError()
  }

#if os(macOS) || os(FreeBSD)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exec(_ executablePath: UnsafePointer<CChar>, argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, withPATH path: UnsafePointer<CChar>) throws -> Never {
    // searchpath must be non-nil
    let code: Int32 = execvP(executablePath, path, argv)
    fatalError("code should be non -1! \(code) error: \(String(cString: strerror(errno)))")
  }
#endif

}

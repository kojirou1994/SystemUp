#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import SystemPackage
import CSystemUp
import CUtility

public enum WaitPID {}

public extension WaitPID {
  static func wait(pid: PID, status: UnsafeMutablePointer<ExitStatus>? = nil, options: Options = [],
                   rusage: UnsafeMutablePointer<rusage>? = nil) -> Result<PID, Errno> {
    SyscallUtilities.valueOrErrno {
      wait4(pid.rawValue, .init(OpaquePointer(status)), options.rawValue, rusage)
    }.map(PID.init)
  }
}

extension WaitPID {
  public struct PID: RawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32
  }

  public struct Options: OptionSet {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32
  }

  public struct ExitStatus: RawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public var rawValue: Int32
  }
}

public extension WaitPID.PID {
  @_alwaysEmitIntoClient
  static var any: Self { .init(rawValue: WAIT_ANY) }

  @_alwaysEmitIntoClient
  static var myProcessGroup: Self { .init(rawValue: WAIT_MYPGRP) }
}

public extension WaitPID.Options {
  @_alwaysEmitIntoClient
  static var noHang: Self { .init(macroValue: WNOHANG) }

  @_alwaysEmitIntoClient
  static var untraced: Self { .init(macroValue: WUNTRACED) }

  #if os(Linux)
  @_alwaysEmitIntoClient
  static var continued: Self { .init(macroValue: WCONTINUED) }
  #endif
}

public extension WaitPID.ExitStatus {
  @_alwaysEmitIntoClient
  var exited: Bool {
    swift_WIFEXITED(rawValue).cBool
  }

  @_alwaysEmitIntoClient
  var exitStatus: Int32 {
    precondition(exited)
    return swift_WEXITSTATUS(rawValue)
  }

  @_alwaysEmitIntoClient
  var signaled: Bool {
    swift_WIFSIGNALED(rawValue).cBool
  }

  @_alwaysEmitIntoClient
  var terminationSignal: Int32 {
    precondition(signaled)
    return swift_WTERMSIG(rawValue)
  }

  @_alwaysEmitIntoClient
  var coreDumped: Bool {
    swift_WCOREDUMP(rawValue).cBool
  }

  @_alwaysEmitIntoClient
  var stopped: Bool {
    swift_WIFSTOPPED(rawValue).cBool
  }

  @_alwaysEmitIntoClient
  var stopSignal: Int32 {
    swift_WSTOPSIG(rawValue)
  }

  @_alwaysEmitIntoClient
  var continued: Bool {
    swift_WIFCONTINUED(rawValue).cBool
  }
}

extension WaitPID.ExitStatus: CustomStringConvertible {
  public var description: String {
    if exited {
      return "exited \(exitStatus)"
    } else if signaled {
      return "signaled \(terminationSignal)"
    } else {
      return "unknown \(rawValue)"
    }
  }
}

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import SystemPackage
import CUtility

public enum WaitPID {}

public extension WaitPID {
  static func wait(pid: PID, status: UnsafeMutablePointer<Int32>? = nil, options: Options = [],
                   rusage: UnsafeMutablePointer<rusage>? = nil) -> Result<PID, Errno> {
    valueOrErrno(retryOnInterrupt: false) {
      wait4(pid.rawValue, status, options.rawValue, rusage)
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

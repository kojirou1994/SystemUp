import SystemLibc
import SystemPackage
import CSystemUp
import CUtility

public enum WaitPID {}

public extension WaitPID {
  @inlinable
  static func wait(pid: PID, status: UnsafeMutablePointer<ExitStatus>? = nil, options: Options = [],
                   rusage: UnsafeMutablePointer<rusage>? = nil) -> Result<PID, Errno> {
    SyscallUtilities.valueOrErrno { () -> pid_t in
      if let rusage {
        return wait4(pid.rawValue, .init(OpaquePointer(status)), options.rawValue, rusage)
      } else {
        return waitpid(pid.rawValue, .init(OpaquePointer(status)), options.rawValue)
      }
    }.map(PID.init)
  }
}

extension WaitPID {

  public struct WaitResult {
    public let pid: PID
    public let status: ExitStatus
  }

  public struct PID: RawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32
  }

  public struct Options: OptionSet, MacroRawRepresentable {

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

public extension WaitPID.PID {
  @_alwaysEmitIntoClient
  static var current: Self { .init(rawValue: getpid()) }

  @_alwaysEmitIntoClient
  static var parent: Self { .init(rawValue: getppid()) }
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
    swift_WEXITSTATUS(rawValue)
  }

  @_alwaysEmitIntoClient
  var signaled: Bool {
    swift_WIFSIGNALED(rawValue).cBool
  }

  @_alwaysEmitIntoClient
  var terminationSignal: Signal {
    .init(rawValue: swift_WTERMSIG(rawValue))
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
  var stopSignal: Signal {
    .init(rawValue: swift_WSTOPSIG(rawValue))
  }

  @_alwaysEmitIntoClient
  var continued: Bool {
    swift_WIFCONTINUED(rawValue).cBool
  }
}

public extension WaitPID.PID {
  @discardableResult
  @inlinable @inline(__always)
  func send(signal: Signal) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.kill(rawValue, signal.rawValue)
    }
  }
}

// MARK: Async Wait
public extension WaitPID.PID {

  /// create new thread to wait
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  func exitStatus(rusage: UnsafeMutablePointer<rusage>? = nil) async throws -> WaitPID.WaitResult {
    try await withCheckedThrowingContinuation { continuation in
      try! PosixThread.detach {
        var status = WaitPID.ExitStatus(rawValue: 0)
        let result = SyscallUtilities.retryWhileInterrupted {
          WaitPID.wait(pid: self, status: &status, options: [], rusage: rusage)
        }
        continuation.resume(with: result.map { .init(pid: $0, status: status) })
      }
    }
  }

  /// check by interval
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  func exitStatus(checkInterval: Duration, rusage: UnsafeMutablePointer<rusage>? = nil) async throws -> WaitPID.WaitResult {
    var status = WaitPID.ExitStatus(rawValue: 0)
    while true {
      let pid = try SyscallUtilities.retryWhileInterrupted {
        WaitPID.wait(pid: self, status: &status, options: .noHang, rusage: rusage)
      }.get()
      if pid.rawValue == 0 {
        // if WNOHANG is specified and there are no stopped or exited children, 0 is returned
        try await Task.sleep(for: checkInterval)
      } else {
        return .init(pid: pid, status: status)
      }
    }
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

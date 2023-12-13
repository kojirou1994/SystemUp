import SystemLibc
import SystemPackage
import CSystemUp
import CUtility

public enum WaitPID {}

public extension WaitPID {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static func wait(_ target: TargetID, status: UnsafeMutablePointer<ExitStatus>? = nil, options: Options = [],
                   rusage: UnsafeMutablePointer<rusage>? = nil) -> Result<ProcessID, Errno> {
    SyscallUtilities.valueOrErrno {
      wait4(target.rawValue, .init(OpaquePointer(status)), options.rawValue, rusage)
    }.map(ProcessID.init)
  }
}

extension WaitPID {

  public struct WaitResult {
    public let pid: ProcessID
    public let status: ExitStatus
  }

  public struct TargetID {
    @usableFromInline
    internal let rawValue: Int32
    @usableFromInline
    internal init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }

  public struct Options: OptionSet {
    public var rawValue: Int32
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }

  public struct ExitStatus: RawRepresentable {
    public var rawValue: Int32
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }
}

public extension WaitPID.TargetID {
  @_alwaysEmitIntoClient
  static var anyProcess: Self { .init(rawValue: WAIT_ANY) }

  @_alwaysEmitIntoClient
  static var anyProcessInMyProcessGroup: Self { .init(rawValue: WAIT_MYPGRP) }

  @_alwaysEmitIntoClient
  static func processID(_ id: ProcessID) -> Self {
    .init(rawValue: id.rawValue)
  }
}

public extension WaitPID.Options {
  @_alwaysEmitIntoClient
  static var noHang: Self { .init(rawValue: WNOHANG) }

  @_alwaysEmitIntoClient
  static var untraced: Self { .init(rawValue: WUNTRACED) }

  #if os(Linux)
  @_alwaysEmitIntoClient
  static var continued: Self { .init(rawValue: WCONTINUED) }
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

// MARK: Async Wait
public extension WaitPID {

  /// create new thread to wait
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  static func exitStatus(of target: TargetID, rusage: UnsafeMutablePointer<rusage>? = nil) async throws -> WaitPID.WaitResult {
    try await withCheckedThrowingContinuation { continuation in
      Task {
        var status = WaitPID.ExitStatus(rawValue: 0)
        let result = SyscallUtilities.retryWhileInterrupted {
          WaitPID.wait(target, status: &status, options: [], rusage: rusage)
        }
        continuation.resume(with: result.map { .init(pid: $0, status: status) })
      }
    }
  }

  /// check by interval
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  static func exitStatus(of target: TargetID, checkInterval: Duration, rusage: UnsafeMutablePointer<rusage>? = nil) async throws -> WaitPID.WaitResult {
    var status = WaitPID.ExitStatus(rawValue: 0)
    while true {
      let pid = try SyscallUtilities.retryWhileInterrupted {
        WaitPID.wait(target, status: &status, options: .noHang, rusage: rusage)
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

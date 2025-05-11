import SystemLibc
import SystemPackage
import CSystemUp
import CUtility

public enum WaitPID {}

public extension WaitPID {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func wait(_ target: TargetID, status: UnsafeMutablePointer<ExitStatus>? = nil, options: Options = [],
                   rusage: UnsafeMutablePointer<ResourceUsage>? = nil) -> Result<ProcessID, Errno> {
    SyscallUtilities.valueOrErrno {
      wait4(target.rawValue, .init(OpaquePointer(status)), options.rawValue, rusage?.pointer(to: \.rawValue))
    }.map(ProcessID.init)
  }
}

extension WaitPID {

  public struct WaitResult: Sendable {
    public let pid: ProcessID
    public let status: ExitStatus
  }

  public struct TargetID: Sendable {
    @usableFromInline
    internal let rawValue: Int32
    @usableFromInline
    internal init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }

  public struct Options: OptionSet {
    public var rawValue: Int32
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }

  public struct ExitStatus: RawRepresentable, Hashable, Sendable {
    public var rawValue: Int32
    @_alwaysEmitIntoClient @inlinable @inline(__always)
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
  /// terminated normally
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var exited: Bool {
    swift_WIFEXITED(rawValue).cBool
  }

  /// returns the exit status of the child. This consists of the least significant 8 bits of the status argument that the child specified in a call to exit(3) or _exit(2) or as the argument for a return statement in main().
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var exitStatus: Int32 {
    assert(exited)
    return swift_WEXITSTATUS(rawValue)
  }

  /// terminated by a signal
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var signaled: Bool {
    swift_WIFSIGNALED(rawValue).cBool
  }

  /// precondition: signaled
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var terminationSignal: Signal {
    assert(signaled)
    return .init(rawValue: swift_WTERMSIG(rawValue))
  }

  /// precondition: signaled
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var coreDumped: Bool {
    assert(signaled)
    return swift_WCOREDUMP(rawValue).cBool
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var stopped: Bool {
    swift_WIFSTOPPED(rawValue).cBool
  }

  /// precondition: stopped
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var stopSignal: Signal {
    assert(stopped)
    return .init(rawValue: swift_WSTOPSIG(rawValue))
  }

  /// returns true if the child process was resumed by delivery of SIGCONT.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var continued: Bool {
    swift_WIFCONTINUED(rawValue).cBool
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func exited(_ exitStatus: Int32) -> Self {
    assert(UInt8(exactly: exitStatus) != nil, "status only supports 8bits, \(exitStatus) will be truncated!")
    return .init(rawValue: swift_W_EXITCODE(exitStatus, 0))
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func signaled(_ signal: Signal) -> Self {
    .init(rawValue: swift_W_EXITCODE(0, signal.rawValue))
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func stopped(_ signal: Signal) -> Self {
    .init(rawValue: swift_W_STOPCODE(signal.rawValue))
  }
}

// MARK: Async Wait
public extension WaitPID {

  /// create new blocked thread to wait
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  static func exitStatus(of target: TargetID) async throws -> WaitResult {
    try await withCheckedThrowingContinuation { continuation in
      try! PosixThread.detach {
        var status = WaitPID.ExitStatus(rawValue: 0)
        let result = SyscallUtilities.retryWhileInterrupted {
          WaitPID.wait(target, status: &status, options: [], rusage: nil)
        }
        continuation.resume(with: result.map { .init(pid: $0, status: consume status) })
      }
    }
  }

  /// check by interval
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  static func exitStatus(of target: TargetID, checkInterval: Duration) async throws -> WaitResult {
    var status = WaitPID.ExitStatus(rawValue: 0)
    while true {
      let pid = try SyscallUtilities.retryWhileInterrupted {
        WaitPID.wait(target, status: &status, options: .noHang, rusage: nil)
      }.get()
      if pid.rawValue == 0 {
        // if WNOHANG is specified and there are no stopped or exited children, 0 is returned
        try await Task.sleep(for: checkInterval)
      } else {
        return .init(pid: pid, status: status)
      }
    }
  }

  /// create new blocked thread to wait
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  static func exitStatusAndUsage(of target: TargetID) async throws -> (WaitResult, ResourceUsage) {
    try await withCheckedThrowingContinuation { continuation in
      try! PosixThread.detach {
        var status = WaitPID.ExitStatus(rawValue: 0)
        var rusage: ResourceUsage = Memory.undefined()
        let result = SyscallUtilities.retryWhileInterrupted {
          WaitPID.wait(target, status: &status, options: [], rusage: &rusage)
        }
        continuation.resume(with: result.map { (.init(pid: $0, status: consume status), consume rusage) })
      }
    }
  }

  /// check by interval
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  static func exitStatusAndUsage(of target: TargetID, checkInterval: Duration) async throws -> (WaitResult, ResourceUsage) {
    var status = WaitPID.ExitStatus(rawValue: 0)
    var rusage: ResourceUsage = Memory.undefined()
    while true {
      let pid = try SyscallUtilities.retryWhileInterrupted {
        WaitPID.wait(target, status: &status, options: .noHang, rusage: &rusage)
      }.get()
      if pid.rawValue == 0 {
        // if WNOHANG is specified and there are no stopped or exited children, 0 is returned
        try await Task.sleep(for: checkInterval)
      } else {
        return (.init(pid: pid, status: status), rusage)
      }
    }
  }

}

extension WaitPID.ExitStatus {
  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  var isSuccess: Bool {
    self == .exited(0)
  }
}

extension WaitPID.ExitStatus: CustomStringConvertible {
  public var description: String {
    if exited {
      return "ExitStatus(exited: \(exitStatus))"
    } else if signaled {
      return "ExitStatus(signaled: \(terminationSignal))"
    } else {
      return "ExitStatus(unknown: \(rawValue))"
    }
  }
}

public extension WaitPID {


  enum ProcessStateChange {
    case pid(ProcessID)
    /// noHang and no children yet
    case noHang
    /// no existing child processes
    case noChildProcess
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static func waitProcessStateChange(_ target: TargetID, status: UnsafeMutablePointer<ExitStatus>? = nil, options: Options = [], rusage: UnsafeMutablePointer<rusage>? = nil) -> ProcessStateChange {
    repeat {
      let result = wait4(target.rawValue, .init(OpaquePointer(status)), options.rawValue, rusage)
      if result == -1 {
        let err = Errno.systemCurrent
        switch err {
        case .interrupted: continue
        case .noChildProcess:
          return .noChildProcess
        case .invalidArgument:
          assertionFailure("The options argument was invalid. value: \(options)")
        default:
          assertionFailure("unknown errno \(err) for syscall waitpid!!")
        }
        // impossible but just return a fake value
        return .noChildProcess
      } else {
        if result == 0 {
          if options.contains(.noHang) {
            return .noHang
          } else {
            assertionFailure("no noHang option but returned 0?")
          }
        }
        return .pid(.init(rawValue: result))
      }
    } while true
  }
}
/*
 @inlinable
 @_alwaysEmitIntoClient
 static func waitProcessStateChange(_ target: TargetID, status: UnsafeMutablePointer<ExitStatus>? = nil, options: Options = [], rusage: UnsafeMutablePointer<rusage>? = nil) -> ProcessStateChange {
 let result = SyscallUtilities.retryWhileInterrupted {
 wait(target, status: status, options: options, rusage: rusage)
 }
 switch result {
 case .success(let pid):
 if pid.rawValue == 0 {
 if options.contains(.noHang) {
 return .noHang
 } else {
 assertionFailure("no noHang option but returned 0?")
 }
 }
 return .pid(pid)
 case .failure(let err):
 switch err {
 case .noChildProcess:
 return .noChildProcess
 case .invalidArgument:
 assertionFailure("The options argument was invalid. value: \(options)")
 default:
 assertionFailure("unknown errno \(err) for syscall waitpid!!")
 }
 // impossible but just return a fake value
 return .noChildProcess
 }
 }
 */

import SystemLibc
import SystemPackage
import CUtility

public struct Signal: RawRepresentable, Hashable, Sendable {
  public let rawValue: CInt

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }
}

public extension Signal {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(handler: SignalHandler, for signals: any Sequence<Self>) {
    signals.forEach { signal in
      assertNoFailure {
        signal.set(handler: handler)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func set(handler: SignalHandler) -> Result<SignalHandler, Errno> {
    assert(self != .kill && self != .stop)
    let result = SystemLibc.signal(rawValue, handler.body)
    if unsafeBitCast(result, to: UnsafeRawPointer?.self) == unsafeBitCast(SystemLibc.SIG_ERR, to: UnsafeRawPointer?.self) {
      return .failure(.systemCurrent)
    }
    return .success(.init(result))
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func set(action: SignalAction) -> Result<SignalAction, Errno> {
    var old: SignalAction = Memory.undefined()
    return set(action: action, oldAction: &old)
      .map { old }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func set(action: SignalAction, oldAction: UnsafeMutablePointer<SignalAction>?) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      withUnsafePointer(to: action.rawValue) { action in
        sigaction(rawValue, action, oldAction?.pointer(to: \.rawValue))
      }
    }
  }

  /// sends a signal to the calling process(single-threaded program) or thread(multithreaded program).
  /// - Returns: void on success or any of the errors specified for the library functions getpid(2) and pthread_kill(2).
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func sendToCurrentThread() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.raise(rawValue)
    }
  }
  
  /// Beginning with Mac OS X 10.7, this string is unique to each thread.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var messageString: StaticCString? {
    SystemLibc.strsignal(rawValue).map { StaticCString(cString: $0) }
  }
}

// MARK: kill
extension Signal {
  public struct SendTargetProcess {
    @usableFromInline
    internal let rawValue: Int32
    @usableFromInline
    internal init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var sameGroupID: Self { .init(rawValue: 0) }

    @_alwaysEmitIntoClient
    public static var all: Self { .init(rawValue: -1) }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public static func processID(_ id: ProcessID) -> Self {
      assert(id.rawValue > 0)
      return .init(rawValue: id.rawValue)
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public static func groupID(_ id: Int32) -> Self {
      assert(id > 1)
      return .init(rawValue: -id)
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func send(to process: SendTargetProcess) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.kill(process.rawValue, rawValue)
    }
  }
}

public extension Signal {

  @_alwaysEmitIntoClient
  static var hangup: Signal { .init(rawValue: SystemLibc.SIGHUP) }

  @_alwaysEmitIntoClient
  static var interrupt: Signal { .init(rawValue: SystemLibc.SIGINT) }

  @_alwaysEmitIntoClient
  static var quit: Signal { .init(rawValue: SystemLibc.SIGQUIT) }

  @_alwaysEmitIntoClient
  static var illegalInstruction: Signal { .init(rawValue: SystemLibc.SIGILL) }

  @_alwaysEmitIntoClient
  static var traceTrap: Signal { .init(rawValue: SystemLibc.SIGTRAP) }

  @_alwaysEmitIntoClient
  static var abort: Signal { .init(rawValue: SystemLibc.SIGABRT) }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient
  static var emulatorTrap: Signal { .init(rawValue: SystemLibc.SIGEMT) }
  #endif

  @_alwaysEmitIntoClient
  static var floatingPointException: Signal { .init(rawValue: SystemLibc.SIGFPE) }

  @_alwaysEmitIntoClient
  static var kill: Signal { .init(rawValue: SystemLibc.SIGKILL) }

  @_alwaysEmitIntoClient
  static var busError: Signal { .init(rawValue: SystemLibc.SIGBUS) }

  @_alwaysEmitIntoClient
  static var segmentationViolation: Signal { .init(rawValue: SystemLibc.SIGSEGV) }

  @_alwaysEmitIntoClient
  static var unknownSystemCall: Signal { .init(rawValue: SystemLibc.SIGSYS) }

  @_alwaysEmitIntoClient
  static var brokenPipe: Signal { .init(rawValue: SystemLibc.SIGPIPE) }

  @_alwaysEmitIntoClient
  static var alarm: Signal { .init(rawValue: SystemLibc.SIGALRM) }

  @_alwaysEmitIntoClient
  static var terminate: Signal { .init(rawValue: SystemLibc.SIGTERM) }

  @_alwaysEmitIntoClient
  static var urgentCondition: Signal { .init(rawValue: SystemLibc.SIGURG) }

  @_alwaysEmitIntoClient
  static var stop: Signal { .init(rawValue: SystemLibc.SIGSTOP) }

  @_alwaysEmitIntoClient
  static var temporaryStop: Signal { .init(rawValue: SystemLibc.SIGTSTP) }

  @_alwaysEmitIntoClient
  static var `continue`: Signal { .init(rawValue: SystemLibc.SIGCONT) }

  @_alwaysEmitIntoClient
  static var childProcessStatusChange: Signal { .init(rawValue: SystemLibc.SIGCHLD) }

  @_alwaysEmitIntoClient
  static var backgroundReadFromControllingTerminal: Signal { .init(rawValue: SystemLibc.SIGTTIN) }

  @_alwaysEmitIntoClient
  static var backgroundWriteToControllingTerminal: Signal { .init(rawValue: SystemLibc.SIGTTOU) }

  @_alwaysEmitIntoClient
  static var ioAvailable: Signal { .init(rawValue: SystemLibc.SIGIO) }

  @_alwaysEmitIntoClient
  static var cpuLimitExceeded: Signal { .init(rawValue: SystemLibc.SIGXCPU) }

  @_alwaysEmitIntoClient
  static var fileSizeLimitExceeded: Signal { .init(rawValue: SystemLibc.SIGXFSZ) }

  @_alwaysEmitIntoClient
  static var virtualAlarm: Signal { .init(rawValue: SystemLibc.SIGVTALRM) }

  @_alwaysEmitIntoClient
  static var profilingAlarm: Signal { .init(rawValue: SystemLibc.SIGPROF) }

  @_alwaysEmitIntoClient
  static var windowSizeChange: Signal { .init(rawValue: SystemLibc.SIGWINCH) }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient
  static var info: Signal { .init(rawValue: SystemLibc.SIGINFO) }
  #endif

  @_alwaysEmitIntoClient
  static var user1: Signal { .init(rawValue: SystemLibc.SIGUSR1) }

  @_alwaysEmitIntoClient
  static var user2: Signal { .init(rawValue: SystemLibc.SIGUSR2) }

}

extension Signal: CustomStringConvertible {
  public var description: String {
    let name = switch self {
    case .interrupt: "interrupt"
    case .terminate: "terminate"
    case .kill: "kill"
    // TODO: Complete Names
    default: "unknown"
    }
    return "Signal(\(name): \(rawValue))"
  }
}

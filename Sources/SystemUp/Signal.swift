import SystemLibc
import SystemPackage

public struct Signal: RawRepresentable {
  public let rawValue: CInt

  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }
}

extension Signal: Comparable {
  public static func < (lhs: Signal, rhs: Signal) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

public extension Signal {

  @inlinable
  static func set(handler: SignalHandler, for signals: any Sequence<Self>) {
    signals.forEach { signal in
      assertNoFailure {
        signal.set(handler: handler)
      }
    }
  }

  @_alwaysEmitIntoClient
  func set(handler: SignalHandler) -> Result<SignalHandler, Errno> {
    assert(self != .kill && self != .stop)
    let result = SystemLibc.signal(rawValue, handler.body)
    if unsafeBitCast(result, to: UnsafeRawPointer?.self) == unsafeBitCast(SystemLibc.SIG_ERR, to: UnsafeRawPointer?.self) {
      return .failure(.systemCurrent)
    }
    return .success(.init(result))
  }

  @_alwaysEmitIntoClient
  func raise() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.raise(rawValue)
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

import SystemLibc
import SystemPackage
import CUtility

public struct SignalAction {
  @usableFromInline
  internal var rawValue: sigaction

  @usableFromInline
  internal init(rawValue: sigaction) {
    self.rawValue = rawValue
  }
}

public extension SignalAction {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  init(blockedSignals: SignalSet = Memory.zeroed(), flags: Flags = [], simple handler: SignalHandler) {
    precondition(!flags.contains(.siginfo), "is using simple handler, siginfo must not be set!")
    #if canImport(Darwin)
    let sigAction = sigaction(__sigaction_u: .init(__sa_handler: handler.body), sa_mask: blockedSignals.rawValue, sa_flags: flags.rawValue)
    #elseif os(Linux)
    let sigAction = sigaction(__sigaction_handler: .init(sa_handler: handler.body), sa_mask: blockedSignals.rawValue, sa_flags: flags.rawValue, sa_restorer: nil)
    #endif
    self.init(rawValue: sigAction)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  init(blockedSignals: SignalSet = Memory.zeroed(), flags: Flags = [], complex handler: @convention(c) (_ signal: Int32, _ siginfo: UnsafeMutablePointer<siginfo_t>?, _ uap: UnsafeMutableRawPointer?) -> Void) {
    let realFlags = flags.union(.siginfo).rawValue
    #if canImport(Darwin)
    let sigAction = sigaction(__sigaction_u: .init(__sa_sigaction: handler), sa_mask: blockedSignals.rawValue, sa_flags: realFlags)
    #elseif os(Linux)
    let sigAction = sigaction(__sigaction_handler: .init(sa_sigaction: handler), sa_mask: blockedSignals.rawValue, sa_flags: realFlags, sa_restorer: nil)
    #endif
    self.init(rawValue: sigAction)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var blockedSignals: SignalSet {
    get { .init(rawValue: rawValue.sa_mask) }
    set { rawValue.sa_mask = newValue.rawValue }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var flags: Flags {
    get { .init(rawValue: rawValue.sa_flags) }
    set { rawValue.sa_flags = newValue.rawValue }
  }
}

extension SignalAction {
  public struct Flags: OptionSet, MacroRawRepresentable {
    public var rawValue: Int32
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }
}

public extension SignalAction.Flags {
  @_alwaysEmitIntoClient
  static var noChildStop: Self { .init(macroValue: SA_NOCLDSTOP) }

  @_alwaysEmitIntoClient
  static var noChildWait: Self { .init(macroValue: SA_NOCLDWAIT) }

  @_alwaysEmitIntoClient
  static var onStack: Self { .init(macroValue: SA_ONSTACK) }

  @_alwaysEmitIntoClient
  static var noDefer: Self { .init(macroValue: SA_NODEFER) }

  @_alwaysEmitIntoClient
  static var resetHandler: Self { .init(macroValue: SA_RESETHAND) }

  @_alwaysEmitIntoClient
  static var restart: Self { .init(macroValue: SA_RESTART) }

  @_alwaysEmitIntoClient
  internal static var siginfo: Self { .init(macroValue: SA_SIGINFO) }
}

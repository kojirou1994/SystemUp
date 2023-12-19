import SystemUp

public struct SignalHandlerManager {
  private static var handlers: [Signal: (Signal) -> Void] = .init()

  public static func set(signal: Signal, handler: @escaping (Signal) -> Void) {
    Self.handlers[signal] = handler
    assertNoFailure {
      signal.set(handler: .custom({ signal in
        let signal = Signal(rawValue: signal)
        Self.handlers[signal]?(signal)
      }))
    }
  }

  public static func ignore(signal: Signal) {
    Self.handlers[signal] = nil
    assertNoFailure {
      signal.set(handler: .ignore)
    }
  }

  public static func reset(signal: Signal) {
    Self.handlers[signal] = nil
    assertNoFailure {
      signal.set(handler: .default)
    }
  }
}

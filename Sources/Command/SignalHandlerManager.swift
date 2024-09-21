import SystemUp
import Synchronization

@available(macOS 15.0, *)
public struct SignalHandlerManager {
  private static let handlers: Mutex<[Signal: (Signal) -> Void]> = .init(.init())

  public static func set(signal: Signal, handler: @escaping @Sendable (Signal) -> Void) {
    Self.handlers.withLock { handlers in
      handlers[signal] = handler
      assertNoFailure {
        signal.set(handler: .custom({ signal in
          let signal = Signal(rawValue: signal)
          Self.handlers.withLock { handlers in
            handlers[signal]?(signal)
          }
        }))
      }
    }
  }

  public static func ignore(signal: Signal) {
    Self.handlers.withLock { handlers in
      handlers[signal] = nil
      assertNoFailure {
        signal.set(handler: .ignore)
      }
    }
  }

  public static func reset(signal: Signal) {
    Self.handlers.withLock { handlers in
      handlers[signal] = nil
      assertNoFailure {
        signal.set(handler: .default)
      }
    }
  }
}

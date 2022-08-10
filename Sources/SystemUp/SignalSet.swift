#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct SignalSet: RawRepresentable {
  public var rawValue: sigset_t

  public init(rawValue: sigset_t) {
    self.rawValue = rawValue
  }

  public init() {
    self.rawValue = .init()
  }
}

public extension SignalSet {
  mutating func add(signal: CInt) {
    sigaddset(&rawValue, signal)
  }

  mutating func delete(signal: CInt) {
    sigdelset(&rawValue, signal)
  }

  mutating func removeAll() {
    sigemptyset(&rawValue)
  }

  mutating func fillAll() {
    sigfillset(&rawValue)
  }

  func contains(signal: CInt) -> Bool {
    withUnsafePointer(to: rawValue) { sigset in
      sigismember(sigset, signal) == 1
    }
  }
}

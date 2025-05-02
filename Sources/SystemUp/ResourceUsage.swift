import SystemLibc
import CUtility
import SystemPackage

public struct ResourceUsage: Sendable {
  @usableFromInline
  internal var rawValue: rusage

  public struct Who: MacroRawRepresentable {
    public let rawValue: Int32
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }
}

public extension ResourceUsage {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func get(for who: Who) {
    assertNoFailure {
      SyscallUtilities.voidOrErrno {
        getrusage(who.rawValue, &rawValue)
      }
    }
  }

}

public extension ResourceUsage.Who {
  @_alwaysEmitIntoClient
  static var currentProcess: Self { .init(macroValue: RUSAGE_SELF) }
  @_alwaysEmitIntoClient
  static var currentProcessChildren: Self { .init(macroValue: RUSAGE_CHILDREN) }
}

import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func check(accessibility: Accessibility, for path: String, relativeTo base: RelativeDirectory = .cwd, flags: AtFlags = []) -> Bool {
    assert(flags.isSubset(of: [.noFollow, .effectiveAccess]))
    return SystemLibc.faccessat(base.toFD, path, accessibility.rawValue, flags.rawValue) == 0
  }

  struct Accessibility: OptionSet, MacroRawRepresentable {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// test for existence of file
    @_alwaysEmitIntoClient
    public static var existence: Self { .init(macroValue: F_OK) }

    /// test for execute or search permission
    @_alwaysEmitIntoClient
    public static var execute: Self { .init(macroValue: X_OK) }

    /// test for write permission
    @_alwaysEmitIntoClient
    public static var write: Self { .init(macroValue: W_OK) }

    @_alwaysEmitIntoClient
    public static var read: Self { .init(macroValue: R_OK) }

  }
}

import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func check(accessibility: FileSyscalls.Accessibility, for path: String, relativeTo base: RelativeDirectory = .cwd, flags: FileSyscalls.AtFlags = []) -> Bool {
    assert(flags.isSubset(of: [.noFollow, .effectiveAccess]))
    return SystemLibc.faccessat(base.toFD, path, accessibility.rawValue, flags.rawValue) == 0
  }

}

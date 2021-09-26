import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct CloneFlags: OptionSet {
  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
  init(_ rawValue: Int32) {
    self.rawValue = .init(rawValue)
  }
  public let rawValue: UInt32

  public static var noFollow: Self { .init(CLONE_NOFOLLOW) }
  public static var noOwnerCopy: Self { .init(CLONE_NOOWNERCOPY) }

}

extension FileUtility {

  @available(macOS 10.12, *)
  public static func cloneFile(from src: FilePath, to dst: FilePath, flags: CloneFlags = []) throws {
    try valueOrErrno(
      src.withPlatformString { src in
        dst.withPlatformString { dst in
          clonefile(src, dst, flags.rawValue)
        }
      }
    )
  }
  
}

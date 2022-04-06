#if canImport(Darwin)
import Darwin
import SystemPackage

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
public extension FileUtility {

  static func cloneFile(from src: FilePathOption, to dst: FilePathOption, flags: CloneFlags = []) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      src.path.withPlatformString { srcPath in
        dst.path.withPlatformString { dstPath in
          clonefileat(
            src.relativedDirFD.rawValue, srcPath,
            dst.relativedDirFD.rawValue, dstPath,
            flags.rawValue
          )
        }
      }
    }.get()
  }

  static func cloneFile(from fd: FileDescriptor, to dst: FilePathOption, flags: CloneFlags = []) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      dst.path.withPlatformString { dstPath in
        fclonefileat(
          fd.rawValue,
          dst.relativedDirFD.rawValue, dstPath,
          flags.rawValue
        )
      }
    }.get()
  }

  struct CloneFlags: OptionSet {
    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }
    public let rawValue: UInt32

    @_alwaysEmitIntoClient
    public static var noFollow: Self { .init(rawValue: numericCast(CLONE_NOFOLLOW)) }
    @_alwaysEmitIntoClient
    public static var noOwnerCopy: Self { .init(rawValue: numericCast(CLONE_NOOWNERCOPY)) }

  }
  
}

#endif // Darwin platform

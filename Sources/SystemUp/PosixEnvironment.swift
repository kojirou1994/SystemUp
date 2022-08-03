#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import CUtility
import SystemPackage

public enum PosixEnvironment {}

public extension PosixEnvironment {

  /// set() may invalidate the result cstring
  static func get<T: StringProtocol>(key: T) -> StaticCString? {
    key.withCString(getenv).map { StaticCString(cString: $0) }
  }

  static func set<T: StringProtocol, R: StringProtocol>(key: T, value: R, overwrite: Bool = true) -> Result<Void, Errno> {
    voidOrErrno {
      key.withCString { key in
        value.withCString { value in
          setenv(key, value, .init(cBool: overwrite))
        }
      }
    }
  }

  @available(*, unavailable, message: "memory leak")
  static func put<T: StringProtocol>(_ string: T) -> Result<Void, Errno> {
    voidOrErrno {
      string.withCString { putenv(strdup($0)) }
    }
  }

  static func unset<T: StringProtocol>(key: T) -> Result<Void, Errno> {
    voidOrErrno {
      key.withCString(unsetenv)
    }
  }

}

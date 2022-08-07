#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import CUtility
import SystemPackage

public struct PosixEnvironment {
  public var environment: [String: String]
  public init(environment: [String: String]) {
    self.environment = environment
  }

  public var envCArray: CStringArray {
    let result = CStringArray()
    result.reserveCapacity(environment.count)
    environment.forEach { result.append("\($0)=\($1)") }
    return result
  }
}

public extension PosixEnvironment {

  static var global: Self {

    var result = Self(environment: .init())

    for entry in NullTerminatedArray(environ) {
      let entry = entry.pointee
      let buffer = UnsafeRawBufferPointer(start: entry, count: UTF8._nullCodeUnitOffset(in: entry))
      if let i = buffer.firstIndex(of: UInt8(ascii: "=")) {
        let key = UnsafeRawBufferPointer(rebasing: buffer[..<i])
        let value = UnsafeRawBufferPointer(rebasing: buffer[i...].dropFirst())
        result.environment[String(decoding: key, as: UTF8.self)] = String(decoding: value, as: UTF8.self)
      }
    }

    return result
  }

  /// set() may invalidate the result cstring
  static func get<T: StringProtocol>(key: T) -> String? {
    key.withCString(getenv).map { String(cString: $0) }
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

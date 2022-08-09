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
      if let finish = strchr(entry, Int32(UInt8(ascii: "="))) {
        let key = UnsafeRawBufferPointer(start: entry, count: finish - entry)
        let value = String(cString: finish.advanced(by: 1))
        result.environment[String(decoding: key, as: UTF8.self)] = value
      }
    }

    return result
  }

  /// set() may invalidate the result cstring
  static func get(key: UnsafePointer<CChar>) -> String? {
    getenv(key).map { String(cString: $0) }
  }

  @discardableResult
  static func set(key: UnsafePointer<CChar>, value: UnsafePointer<CChar>, overwrite: Bool = true) -> Result<Void, Errno> {
    voidOrErrno {
      setenv(key, value, .init(cBool: overwrite))
    }
  }

  @available(*, unavailable, message: "memory leak")
  static func put<T: StringProtocol>(_ string: T) -> Result<Void, Errno> {
    voidOrErrno {
      string.withCString { putenv(strdup($0)) }
    }
  }

  @discardableResult
  static func unset(key: UnsafePointer<CChar>) -> Result<Void, Errno> {
    voidOrErrno {
      unsetenv(key)
    }
  }

}

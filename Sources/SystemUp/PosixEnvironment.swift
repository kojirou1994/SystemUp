import SystemLibc
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
    environment.forEach { result.append(.copy(bytes: "\($0)=\($1)")) }
    return result
  }
}

public extension PosixEnvironment {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var environ: NullTerminatedArray<UnsafeMutablePointer<CChar>> {
    let environ: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
    #if canImport(Darwin)
    environ = NSGetEnviron().pointee
    #elseif os(Linux)
    environ = swift_get_environ()
    #endif
    return .init(environ)
  }

  /// not thread-safe
  static var global: Self {

    var result = Self(environment: .init())

    for entry in environ {
      let entry = entry.pointee
      if let finish = strchr(entry, Int32(UInt8(ascii: "="))) {
        let key = UnsafeRawBufferPointer(start: entry, count: finish - entry)
        let value = String(cString: finish.advanced(by: 1))
        result.environment[String(decoding: key, as: UTF8.self)] = value
      }
    }

    return result
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getenv<R>(_ key: UnsafePointer<CChar>, _ body: (UnsafePointer<CChar>?) -> R) -> R {
    body(SystemLibc.getenv(key))
  }

  /// set() may invalidate the result cstring
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func get(key: UnsafePointer<CChar>) -> String? {
    getenv(key) { $0.map(String.init(cString: )) }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func set(key: UnsafePointer<CChar>, value: UnsafePointer<CChar>, overwrite: Bool = true) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.setenv(key, value, .init(cBool: overwrite))
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func put(_ string: consuming DynamicCString) -> Result<Void, Errno> {
    let cString = string.take()
    return SyscallUtilities.voidOrErrno {
      SystemLibc.putenv(cString)
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func unset(key: UnsafePointer<CChar>) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      return SystemLibc.unsetenv(key)
    }
  }

}

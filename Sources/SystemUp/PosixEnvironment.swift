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

  static var lock = try! PosixMutex.create().get()

  /// not thread-safe
  static var global: Self {
    lock.lock()
    defer {
      lock.unlock()
    }

    var result = Self(environment: .init())

    for entry in NullTerminatedArray(SystemLibc.environ) {
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
  @_alwaysEmitIntoClient
  static func get(key: UnsafePointer<CChar>) -> String? {
    SystemLibc.getenv(key).map { String(cString: $0) }
  }

  @discardableResult
  @_alwaysEmitIntoClient
  static func set(key: UnsafePointer<CChar>, value: UnsafePointer<CChar>, overwrite: Bool = true) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.setenv(key, value, .init(cBool: overwrite))
    }
  }

  @available(*, unavailable, message: "memory leak")
  @_alwaysEmitIntoClient
  static func put<T: StringProtocol>(_ string: T) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      string.withCString { SystemLibc.putenv(strdup($0)) }
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient
  static func unset(key: UnsafePointer<CChar>) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.unsetenv(key)
    }
  }

}

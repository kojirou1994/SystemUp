import SystemPackage
import SystemLibc
import CUtility

/// mt-safe on darwin
public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getenv(_ name: borrowing some CStringConvertible & ~Copyable) -> UnsafeMutablePointer<CChar>? {
    name.withUnsafeCString { SystemLibc.getenv($0) }
  }


  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func setenv(name: borrowing some CStringConvertible & ~Copyable, value: borrowing some CStringConvertible & ~Copyable, overwrite: Bool = true) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      name.withUnsafeCString { name in
        value.withUnsafeCString { value in
          SystemLibc.setenv(name, value, .init(cBool: overwrite))
        }
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func putenv(_ string: consuming UnsafeMutablePointer<CChar>) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.putenv(string)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func unsetenv(name: borrowing some CStringConvertible & ~Copyable) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      name.withUnsafeCString { name in
        SystemLibc.unsetenv(name)
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var _environ: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
    let environ: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
    #if canImport(Darwin)
    environ = NSGetEnviron().pointee
    #elseif os(Linux)
    environ = swift_get_environ()
    #endif
    return environ
  }

  #if canImport(Darwin)
  @_extern(c, "environ_lock_np")
  static func _lockEnviron()

  @_extern(c, "environ_unlock_np")
  static func _unlockEnviron()
  #endif
}

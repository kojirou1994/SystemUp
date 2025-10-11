import SystemPackage
import SystemLibc
import CUtility

public extension Errno {

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  static var systemCurrent: Self {
    get { .init(rawValue: SystemLibc.swift_get_errno()) }
    set { SystemLibc.swift_set_errno(newValue.rawValue) }
  }

  /// set errno to 0.
  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  static func reset() {
    systemCurrent = .init(rawValue: 0)
  }

  /// returns nil if errno is 0.
  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  static var systemCurrentValid: Self? {
    let v = SystemLibc.swift_get_errno()
    return v == 0 ? nil : .init(rawValue: v)
  }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  var errorMessage: StaticCString? {
    SystemLibc.strerror(rawValue).map { .init(cString: $0) }
  }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  func copyErrorMessage(to buf: UnsafeMutableBufferPointer<CChar>) throws(Errno) {
    assert(!buf.isEmpty)
    try SyscallUtilities.errnoOrZeroOnReturn {
      SystemLibc.strerror_r(rawValue, buf.baseAddress.unsafelyUnwrapped, buf.count)
    }.get()
  }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  static func print(_ string: borrowing some CString) {
    string.withUnsafeCString { string in
      perror(string)
    }
  }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  static func print() {
    perror(nil)
  }
}

#if canImport(Darwin)
extension Errno: @retroactive CaseIterable {
  public static var allCases: some Collection<Errno> {
    let n = 0..<SystemLibc.sys_nerr
    let s = n.lazy.map(Errno.init)
    return s
  }
}
#endif

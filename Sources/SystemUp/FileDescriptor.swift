import SystemPackage
import SystemLibc
import SyscallValue
import CUtility

extension FileDescriptor {
  public func read<T: SyscallValue>(upToCount count: Int) throws(Errno) -> T {
    try toTypedThrows(Errno.self) {
      try T.init(bytesCapacity: count) { buffer in
        try read(into: buffer)
      }
    }
  }

  @inlinable @inline(__always)
  internal static var currentWorkingDirectory: Self { .init(rawValue: SystemLibc.AT_FDCWD) }
}

// MARK: TTY
public extension FileDescriptor {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func isatty() throws(Errno) {
    let ret = SystemLibc.isatty(rawValue)
    assert([0, 1].contains(ret))
    if ret == 1 {
      return
    } else {
      // should be 0
      throw .systemCurrent
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var isTerminal: Bool {
    do {
      try isatty()
      return true
    } catch {
      return false
    }
  }

  /// name stored in a static buffer which will be overwritten on subsequent calls
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var unsafeTTYName: StaticCString? {
    ttyname(rawValue).map { StaticCString(cString: $0) }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getTTYName(into buffer: UnsafeMutablePointer<CChar>, capacity: Int) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      ttyname_r(rawValue, buffer, capacity)
    }.get()
  }

//  var ttyName: String? {
//    let capacity = Int(PATH_MAX)
//    return try? String(bytesCapacity: capacity) { buffer in
//      let buffer = buffer.assumingMemoryBound(to: CChar.self)
//      switch getTTYName(into: buffer.baseAddress!, capacity: buffer.count) {
//      case .success: break
//      case .failure(let err):
//        assert(err != .outOfRange, "The bufsize is too small!!")
//        throw err
//      }
//      return strlen(buffer.baseAddress!)
//    }
//  }

}

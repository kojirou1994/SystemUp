import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileStatus(_ fd: FileDescriptor, into status: UnsafeMutablePointer<FileStatus>) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.fstat(fd.rawValue, status.pointer(to: \.rawValue)!)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileStatus(_ path: UnsafePointer<CChar>, relativeTo base: RelativeDirectory = .cwd, flags: AtFlags = [], into status: UnsafeMutablePointer<FileStatus>) throws(Errno) {
    assert(flags.isSubset(of: [.noFollow]))
    try SyscallUtilities.voidOrErrno {
      SystemLibc.fstatat(base.toFD, path, status.pointer(to: \.rawValue)!, flags.rawValue)
    }.get()
  }
}

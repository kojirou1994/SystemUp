import CUtility
import CGeneric
import SystemPackage
import SystemLibc

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileStatus(_ fd: FileDescriptor, into status: UnsafeMutablePointer<FileStatus>) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.fstat(fd.rawValue, status.pointer(to: \.rawValue)!)
    }
  }

  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func fileStatus(_ path: String, relativeTo base: RelativeDirectory = .cwd, flags: AtFlags = [], into status: UnsafeMutablePointer<FileStatus>) -> Result<Void, Errno> {
    assert(flags.isSubset(of: [.noFollow]))
    return SyscallUtilities.voidOrErrno {
      SystemLibc.fstatat(base.toFD, path, status.pointer(to: \.rawValue)!, flags.rawValue)
    }
  }
}

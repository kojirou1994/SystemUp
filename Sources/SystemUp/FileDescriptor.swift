import SystemPackage
import SystemLibc
import SyscallValue

extension FileDescriptor {
  public func read<T: SyscallValue>(upToCount count: Int) throws -> T {
    try T.init(capacity: count) { ptr in
      try read(into: UnsafeMutableRawBufferPointer(start: ptr, count: count))
    }
  }

  @inlinable @inline(__always)
  public static var currentWorkingDirectory: Self { .init(rawValue: SystemLibc.AT_FDCWD) }
}

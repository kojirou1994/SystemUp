#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#else
#error("Unsupported platform!")
#endif

@usableFromInline
internal func system_access(_ fd: Int32, _ path: UnsafePointer<CChar>, _ accessibility: Int32, _ flags: Int32) -> Int32 {
  faccessat(fd, path, accessibility, flags)
}

@usableFromInline
func system_truncate(_ path: UnsafePointer<CChar>, _ size: off_t) -> Int32 {
  truncate(path, size)
}

@usableFromInline
func system_ftruncate(_ fd: Int32, _ size: off_t) -> Int32 {
  ftruncate(fd, size)
}

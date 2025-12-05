import SystemLibc
import CUtility

public enum Memory {}

public extension Memory {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func zeroed<T>() -> T {
    withUnsafeTemporaryAllocation(of: T.self, capacity: 1) { buf in
      UnsafeMutableRawBufferPointer(buf).initializeMemory(as: UInt8.self, repeating: 0)
      return buf[0]
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func undefined<T>() -> T {
    withUnsafeTemporaryAllocation(of: T.self, capacity: 1) { buf in
      return buf[0]
    }
  }
}

// MARK: malloc series
public extension Memory {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func allocate(byteCount: Int, alignment: Int? = nil) throws(Errno) -> UnsafeMutableRawPointer {
    try SyscallUtilities.unwrap {
      if let alignment {
        SystemLibc.aligned_alloc(alignment, byteCount)
      } else {
        SystemLibc.malloc(byteCount)
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func allocateZeroed(size: Int, count: Int) throws(Errno) -> UnsafeMutableRawPointer {
    try SyscallUtilities.unwrap {
      SystemLibc.calloc(count, size)
    }.get()
  }

  /// posix_memalign
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func allocateAligned(size: Int, alignment: Int) throws(Errno) -> UnsafeMutableRawPointer {
    try safeInitialize { memptr throws(Errno) in
      try SyscallUtilities.errnoOrZeroOnReturn {
        SystemLibc.posix_memalign(&memptr, alignment, size)
      }.get()
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func free(_ ptr: UnsafeMutableRawPointer?) {
    SystemLibc.free(ptr)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func resize(_ ptr: inout UnsafeMutableRawPointer, byteCount: Int) throws(Errno) {
    ptr = try resized(ptr, byteCount: byteCount)
  }

  /// If ptr is NULL, realloc() is identical to a call to malloc() for size bytes.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func resized(_ ptr: UnsafeMutableRawPointer?, byteCount: Int) throws(Errno) -> UnsafeMutableRawPointer {
    // darwin: If size is zero and ptr is not NULL, a new, minimum sized object is allocated and the original object is freed.
    // gnu: If size is zero, and ptr is not NULL, then the call is equivalent to free(ptr)
    #if canImport(Glibc)
    assert(byteCount > 0, "use free! ok?")
    #endif

    return try SyscallUtilities.unwrap {
      SystemLibc.realloc(ptr, byteCount)
    }.get()
  }

  #if APPLE
  /// it will free the passed pointer when the requested memory cannot be allocated
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func resizeOrFree(_ ptr: consuming UnsafeMutableRawPointer?, byteCount: Int) throws(Errno) -> UnsafeMutableRawPointer {
    try SyscallUtilities.unwrap {
      SystemLibc.reallocf(ptr, byteCount)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func blockSize(of ptr: UnsafeRawPointer) -> Int {
    SystemLibc.malloc_size(ptr)
  }

  /// rounds size up to a value that the allocator implementation can allocate without adding any padding; it then returns that rounded-up value.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func goodSize(_ size: Int) -> Int {
    SystemLibc.malloc_good_size(size)
  }
  #endif

  // MARK: Wrappers

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func allocate<T>(of type: T.Type, capacity: Int, alignment: Int? = nil) throws(Errno) -> UnsafeMutableBufferPointer<T> {
    let byteCount = capacity * MemoryLayout<T>.stride
    return try .init(start: allocate(byteCount: byteCount, alignment: alignment).assumingMemoryBound(to: T.self), count: capacity)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func allocateZeroed<T>(of type: T.Type, capacity: Int) throws(Errno) -> UnsafeMutableBufferPointer<T> {
    try .init(start: allocateZeroed(size: MemoryLayout<T>.stride, count: capacity).assumingMemoryBound(to: T.self), count: capacity)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func resize<T>(_ buf: inout UnsafeMutableBufferPointer<T>, capacity: Int) throws(Errno) {
    buf = try .init(start: resized(buf.baseAddress, byteCount: capacity * MemoryLayout<T>.stride).assumingMemoryBound(to: T.self), count: capacity)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func resize(_ buf: inout UnsafeMutableRawBufferPointer, byteCount: Int) throws(Errno) {
    buf = try .init(start: resized(buf.baseAddress, byteCount: byteCount), count: byteCount)
  }
}

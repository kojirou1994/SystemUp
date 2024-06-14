import SystemLibc
import SystemPackage

public enum Memory {}

public extension Memory {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func zeroed<T>() -> T {
    withUnsafeTemporaryAllocation(of: T.self, capacity: 1) { buf in
      UnsafeMutableRawBufferPointer(buf).initializeMemory(as: UInt8.self, repeating: 0)
      return buf[0]
    }
  }
}

// MARK: malloc series
public extension Memory {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func allocate(byteCount: Int, alignment: Int? = nil) -> Result<UnsafeMutableRawPointer, Errno> {
    SyscallUtilities.unwrap {
      if let alignment {
        SystemLibc.aligned_alloc(alignment, byteCount)
      } else {
        SystemLibc.malloc(byteCount)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func allocateZeroed(size: Int, count: Int) -> Result<UnsafeMutableRawPointer, Errno> {
    SyscallUtilities.unwrap {
      SystemLibc.calloc(count, size)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func free(_ ptr: consuming UnsafeMutableRawPointer?) {
    SystemLibc.free(ptr)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func resize(_ ptr: inout UnsafeMutableRawPointer, byteCount: Int) throws {
    ptr = try resized(ptr, byteCount: byteCount).get()
  }

  /// If ptr is NULL, realloc() is identical to a call to malloc() for size bytes.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func resized(_ ptr: UnsafeMutableRawPointer?, byteCount: Int) -> Result<UnsafeMutableRawPointer, Errno> {
    // darwin: If size is zero and ptr is not NULL, a new, minimum sized object is allocated and the original object is freed.
    // gnu: If size is zero, and ptr is not NULL, then the call is equivalent to free(ptr)
    #if canImport(Glibc)
    assert(byteCount > 0, "use free! ok?")
    #endif

    return SyscallUtilities.unwrap {
      SystemLibc.realloc(ptr, byteCount)
    }
  }

  #if canImport(Darwin)
  /// it will free the passed pointer when the requested memory cannot be allocated
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func resizeOrFree(_ ptr: consuming UnsafeMutableRawPointer?, byteCount: Int) -> Result<UnsafeMutableRawPointer, Errno> {
    SyscallUtilities.unwrap {
      SystemLibc.reallocf(ptr, byteCount)
    }
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
  static func allocate<T>(of type: T.Type, capacity: Int, alignment: Int? = nil) -> Result<UnsafeMutableBufferPointer<T>, Errno> {
    let byteCount = capacity * MemoryLayout<T>.stride
    return allocate(byteCount: byteCount, alignment: alignment)
      .map { .init(start: $0.assumingMemoryBound(to: T.self), count: capacity) }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func allocateZeroed<T>(of type: T.Type, capacity: Int) -> Result<UnsafeMutableBufferPointer<T>, Errno> {
    allocateZeroed(size: MemoryLayout<T>.stride, count: capacity)
      .map { .init(start: $0.assumingMemoryBound(to: T.self), count: capacity) }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func resize<T>(_ buf: inout UnsafeMutableBufferPointer<T>, capacity: Int) throws {
    buf = try .init(start: resized(buf.baseAddress, byteCount: capacity * MemoryLayout<T>.stride).get().assumingMemoryBound(to: T.self), count: capacity)
  }
}

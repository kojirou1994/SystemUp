import SystemLibc

public struct FileDescriptor: RawRepresentable, Hashable, Sendable {
  public let rawValue: CInt
  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }
}

public extension FileDescriptor {
  @_alwaysEmitIntoClient
  static var standardInput: Self { .init(rawValue: 0) }

  @_alwaysEmitIntoClient
  static var standardOutput: Self { .init(rawValue: 1) }

  @_alwaysEmitIntoClient
  static var standardError: Self { .init(rawValue: 2) }
}

extension FileDescriptor {
  public struct AccessMode: RawRepresentable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    public static var readOnly: AccessMode { AccessMode(rawValue: O_RDONLY) }

    @_alwaysEmitIntoClient
    public static var writeOnly: AccessMode { AccessMode(rawValue: O_WRONLY) }

    @_alwaysEmitIntoClient
    public static var readWrite: AccessMode { AccessMode(rawValue: O_RDWR) }

  }

  public struct OpenOptions: OptionSet, Sendable, Hashable {
    /// The raw C options.
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    /// Create a strongly-typed options value from raw C options.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

#if !os(Windows)
    @_alwaysEmitIntoClient
    public static var nonBlocking: OpenOptions { .init(rawValue: O_NONBLOCK) }

#endif

    @_alwaysEmitIntoClient
    public static var append: OpenOptions { .init(rawValue: O_APPEND) }

    @_alwaysEmitIntoClient
    public static var create: OpenOptions { .init(rawValue: O_CREAT) }

    @_alwaysEmitIntoClient
    public static var truncate: OpenOptions { .init(rawValue: O_TRUNC) }

    @_alwaysEmitIntoClient
    public static var exclusiveCreate: OpenOptions { .init(rawValue: O_EXCL) }

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)

    @_alwaysEmitIntoClient
    public static var sharedLock: OpenOptions { .init(rawValue: O_SHLOCK) }

    @_alwaysEmitIntoClient
    public static var exclusiveLock: OpenOptions { .init(rawValue: O_EXLOCK) }
#endif

#if !os(Windows)

    @_alwaysEmitIntoClient
    public static var noFollow: OpenOptions { .init(rawValue: O_NOFOLLOW) }

    @_alwaysEmitIntoClient
    public static var directory: OpenOptions { .init(rawValue: O_DIRECTORY) }

#endif

#if os(FreeBSD)

    @_alwaysEmitIntoClient
    public static var sync: OpenOptions { .init(rawValue: O_SYNC) }

#endif

#if SYSTEM_PACKAGE_DARWIN

    @_alwaysEmitIntoClient
    public static var symlink: OpenOptions { .init(rawValue: O_SYMLINK) }

    @_alwaysEmitIntoClient
    public static var eventOnly: OpenOptions { .init(rawValue: O_EVTONLY) }

#endif

#if !os(Windows)

    @_alwaysEmitIntoClient
    public static var closeOnExec: OpenOptions { .init(rawValue: O_CLOEXEC) }

#endif
  }
}

// MARK: System APIs
public extension FileDescriptor {
  /// retryOnInterrupt
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func read(into buffer: UnsafeMutableRawBufferPointer) throws(Errno) -> Int {
    try SyscallUtilities.retryWhileInterrupted { () throws(Errno) in
      try SystemCall.read(self, into: buffer)
    }
  }

  /// retryOnInterrupt
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func write(_ buffer: UnsafeRawBufferPointer) throws(Errno) -> Int {
    try SyscallUtilities.retryWhileInterrupted { () throws(Errno) in
      try SystemCall.write(self, buffer: buffer)
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func writeAll(_ buffer: UnsafeRawBufferPointer) throws(Errno) -> Int  {
    var written = 0
    while written < buffer.count {
      let numBytes = try write(UnsafeRawBufferPointer(rebasing: buffer.dropFirst(written)))
      written += numBytes
    }
    assert(written == buffer.count)
    return buffer.count
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func closeAfter<R, E: Error>(_ body: (Self) throws(E) -> R) throws(E) -> R {
    defer {
      try? close()
    }
    return try body(self)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func close() throws(Errno) {
    try SystemCall.close(self)
  }
}


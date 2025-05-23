import SystemPackage
import SystemLibc
import CUtility

public struct Directory: ~Copyable {

  #if canImport(Darwin)
  @usableFromInline
  typealias CDirectoryStream = UnsafeMutablePointer<DIR>
  #else
  @usableFromInline
  typealias CDirectoryStream = OpaquePointer
  #endif

  @_alwaysEmitIntoClient
  private init(_ dir: CDirectoryStream) {
    self.dir = dir
  }

  @_alwaysEmitIntoClient
  private let dir: CDirectoryStream

  @_alwaysEmitIntoClient
  public static func open(_ path: borrowing some CStringConvertible & ~Copyable) throws(Errno) -> Self {
    .init(try SyscallUtilities.unwrap {
      path.withUnsafeCString { path in
        opendir(path)
      }
    }.get())
  }

  @_alwaysEmitIntoClient
  public static func open(_ fd: FileDescriptor) throws(Errno) -> Self {
    try .init(SyscallUtilities.unwrap {
      fdopendir(fd.rawValue)
    }.get())
  }

  @_alwaysEmitIntoClient
  deinit {
    assertNoFailure {
      SyscallUtilities.voidOrErrno { closedir(dir) }
    }
  }

  /// release Directory but keep stream opened, use with open(_ fd: FileDescriptor)
  @_alwaysEmitIntoClient
  public consuming func keepOpened() {
    discard self
  }

  /// return current location in directory stream
  @_alwaysEmitIntoClient
  public func tell() -> Int {
    let r = telldir(dir)
    assert(r != -1)
    return r
  }

  /// resets the position of the named directory stream to the beginning of the directory.
  @_alwaysEmitIntoClient
  public func rewind() {
    rewinddir(dir)
  }

  /// sets the position of the next readdir() operation on the directory stream
  @_alwaysEmitIntoClient
  public func seek(to location: Int) {
    seekdir(dir, location)
  }

  /// returns the integer file descriptor associated with the named directory stream
  @_alwaysEmitIntoClient
  public var fd: FileDescriptor {
    .init(rawValue: dirfd(dir))
  }

  @available(*, deprecated, message: "unsafe")
  @_alwaysEmitIntoClient
  public func read(into entry: UnsafeMutablePointer<dirent>) -> Result<Bool, Errno> {
    var entryPtr: UnsafeMutablePointer<dirent>?
    return SyscallUtilities.voidOrErrno {
      readdir_r(dir, entry, &entryPtr)
    }
    .map { _ in
      if _slowPath(entryPtr == nil) {
        return false
      }
      assert(OpaquePointer(entry) == OpaquePointer(entryPtr))
      return true
    }
  }

  /// directory stream iterate helper
  @_alwaysEmitIntoClient
  public func forEachEntries(_ body: (borrowing Entry, _ stop: inout Bool) throws -> Void) throws {
    var stop = false
    while !stop {
      if let entry = try next() {
        // success
        try body(entry, &stop)
      } else {
        // no entry
        return
      }
    }
  }

  /// not thread-safe
  /// don't save result, unsafe now, dot file ignored.
  @_alwaysEmitIntoClient
  public func next(resetErrno: Bool = true) throws(Errno) -> Entry? {
    if resetErrno {
      Errno.reset()
    }
    while true {
      if let ptr = readdir(dir) {
        let entry = Entry(ptr)
        if entry.isDot {
          continue
        }
        return entry
      } else {
        if let err = Errno.systemCurrentValid {
          // errno changed, error happened!
          throw err
        } else {
          // end of stream
          return nil
        }
      }
    }
  }

}

extension Directory {

  public struct Entry: ~Copyable {

    @usableFromInline
    internal let entry: UnsafeMutablePointer<dirent>

    @_alwaysEmitIntoClient
    init(_ entry: UnsafeMutablePointer<dirent>) {
      self.entry = entry
    }

    @_alwaysEmitIntoClient
    public var entryFileNumber: CInterop.UpInodeNumber {
      entry.pointee.d_ino
    }

    @_alwaysEmitIntoClient
    public var seekOffset: CInterop.UpSeekOffset {
      #if canImport(Darwin)
      return entry.pointee.d_seekoff
      #else
      return entry.pointee.d_off
      #endif
    }

    @_alwaysEmitIntoClient
    public var recordLength: UInt16 {
      entry.pointee.d_reclen
    }

    @_alwaysEmitIntoClient
    public var fileType: DirectoryType {
      DirectoryType(rawValue: entry.pointee.d_type)
    }

    @_alwaysEmitIntoClient
    public var isHidden: Bool {
      entry.pointee.d_name.0 == UInt8(ascii: ".")
    }

    /// is "." or ".."
    @_alwaysEmitIntoClient
    public var isDot: Bool {
      let point = UInt8(ascii: ".")
      return (entry.pointee.d_name.0 == point && entry.pointee.d_name.1 == 0)
      || (entry.pointee.d_name.0 == point && entry.pointee.d_name.1 == point && entry.pointee.d_name.2 == 0)
    }

    /// entry name (up to MAXPATHLEN bytes)
    @_alwaysEmitIntoClient
    public var name: String {
      withNameCString { cString in
        cString.withUnsafeCString { cString in
          String(decoding: UnsafeRawBufferPointer(start: cString, count: nameLength), as: UTF8.self)
        }
      }
    }

    @_alwaysEmitIntoClient
    public var nameLength: Int {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      Int(entry.pointee.d_namlen)
#else
      withNameCString { $0.length }
#endif
    }

    // TODO: Name Span

    @_alwaysEmitIntoClient
    public func withNameCString<R: ~Copyable, E: Error>(_ body: (borrowing DynamicCString) throws(E) -> R) throws(E) -> R {
      try DynamicCString.withTemporaryBorrowed(cString: UnsafeRawPointer(entry.pointer(to: \.d_name)!).assumingMemoryBound(to: CChar.self), body)
    }
  }

}

extension Directory {
  public struct DirectoryType: MacroRawRepresentable, Equatable {

    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }

    public let rawValue: UInt8
  }

}
extension Directory.DirectoryType {

  @_alwaysEmitIntoClient
  public static var unknown: Self { .init(macroValue: DT_UNKNOWN) }

  @_alwaysEmitIntoClient
  public static var namedPipe: Self { .init(macroValue: DT_FIFO) }

  @_alwaysEmitIntoClient
  public static var character: Self { .init(macroValue: DT_CHR) }

  @_alwaysEmitIntoClient
  public static var directory: Self { .init(macroValue: DT_DIR) }

  @_alwaysEmitIntoClient
  public static var block: Self { .init(macroValue: DT_BLK) }

  @_alwaysEmitIntoClient
  public static var regular: Self { .init(macroValue: DT_REG) }

  @_alwaysEmitIntoClient
  public static var symbolicLink: Self { .init(macroValue: DT_LNK) }

  @_alwaysEmitIntoClient
  public static var socket: Self { .init(macroValue: DT_SOCK) }

  @_alwaysEmitIntoClient
  public static var wht: Self { .init(macroValue: DT_WHT) }

}

extension Directory.DirectoryType: CustomStringConvertible {

  @inline(never)
  public var description: String {
    switch self {
    case .namedPipe: return "namedPipe"
    case .character: return "character"
    case .directory: return "directory"
    case .block: return "block"
    case .regular: return "regular"
    case .symbolicLink: return "symbolicLink"
    case .socket: return "socket"
    case .wht: return "wht"
    case .unknown: return "unknown"
    default: return unknownDescription
    }
  }

}

import SystemPackage
import SystemLibc
import CUtility
import CGeneric

public struct Directory {

  #if canImport(Darwin)
  @usableFromInline
  typealias CDirectoryStream = UnsafeMutablePointer<DIR>
  #else
  @usableFromInline
  typealias CDirectoryStream = OpaquePointer
  #endif

  @usableFromInline
  internal init(_ dir: CDirectoryStream) {
    self.dir = dir
  }

  @usableFromInline
  internal let dir: CDirectoryStream

  @CStringGeneric()
  @_alwaysEmitIntoClient
  public static func open(_ path: String) -> Result<Self, Errno> {
    SyscallUtilities.unwrap {
      .init(opendir(path))
    }
  }

  @_alwaysEmitIntoClient
  public static func open(_ fd: FileDescriptor) -> Result<Self, Errno> {
    SyscallUtilities.unwrap {
      .init(fdopendir(fd.rawValue))
    }
  }

  @_alwaysEmitIntoClient
  public func close() {
    assertNoFailure {
      SyscallUtilities.voidOrErrno { closedir(dir) }
    }
  }

  @_alwaysEmitIntoClient
  public func tell() throws -> Int {
    telldir(dir)
  }

  /// resets the position of the named directory stream to the beginning of the directory.
  @_alwaysEmitIntoClient
  public func rewind() throws {
    rewinddir(dir)
  }

  @_alwaysEmitIntoClient
  public func seek(offset: Int) throws {
    seekdir(dir, offset)
  }

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
      if (try withNextEntry({ try body($0, &stop) })?.get()) != nil {
        // success
      } else {
        // no entry
        return
      }
    }
  }

  /// not thread-safe, dot . and .. is ignored
  @_alwaysEmitIntoClient
  public func withNextEntry<R>(_ body: (borrowing Entry) throws -> R) rethrows -> Result<R, Errno>? {
    while true {
      Errno.systemCurrent = .init(rawValue: 0)
      let ptr = readdir(dir)
      if let ptr {
        let entry = Entry(ptr)
        if entry.isDot {
          continue
        }
        return try .success(body(entry))
      } else {
        if case let err = Errno.systemCurrent,
           err.rawValue != 0 {
          // errno changed, error happened!
          return .failure(err)
        } else {
          // end of stream
          return nil
        }
      }
    }
  }

  @_alwaysEmitIntoClient
  public func closeAfter<R>(_ body: (Self) throws -> R) throws -> R {
    defer { close() }
    return try body(self)
  }

}

extension dirent {
  @inlinable
  internal var isDot: Bool {
    let point = UInt8(ascii: ".")
    return (d_name.0 == point && d_name.1 == 0)
    || (d_name.0 == point && d_name.1 == point && d_name.2 == 0)
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
      #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
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
    internal var isDot: Bool {
      entry.pointee.isDot
    }

    /// entry name (up to MAXPATHLEN bytes)
    @_alwaysEmitIntoClient
    public var name: String {
      withNameBuffer { buffer in
        String(decoding: buffer, as: UTF8.self)
      }
    }

    @_alwaysEmitIntoClient
    public func withNameBuffer<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
      try withNameCString { cString in
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        let length = Int(entry.pointee.d_namlen)
        #else
        let length = strlen(cString)
        #endif

        return try body(.init(start: cString, count: length))
      }
    }

    @_alwaysEmitIntoClient
    public func withNameCString<R>(_ body: (UnsafePointer<CChar>) throws -> R) rethrows -> R {
      try body(UnsafeRawPointer(entry.pointer(to: \.d_name)!).assumingMemoryBound(to: CChar.self))
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
    default: return unknownDescription
    }
  }

}

import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
import CSystemUp
#endif

public struct Directory {

  #if canImport(Darwin)
  typealias CDirectoryStream = UnsafeMutablePointer<DIR>
  #else
  typealias CDirectoryStream = OpaquePointer
  #endif

  private init(_ dir: CDirectoryStream) {
    self.dir = dir
  }

  private let dir: CDirectoryStream

  public static func open(_ path: FilePath) -> Result<Self, Errno> {
    guard let dir = path.withPlatformString(opendir) else {
      return .failure(.current)
    }
    return .success(.init(dir))
  }

  public static func open(_ fd: FileDescriptor) -> Result<Self, Errno> {
    guard let dir = fdopendir(fd.rawValue) else {
      return .failure(.current)
    }
    return .success(.init(dir))
  }

  public func close() {
    neverError {
      try nothingOrErrno(retryOnInterrupt: false, { closedir(dir) }).get()
    }
  }

  public func tell() throws -> Int {
    telldir(dir)
  }

  /// resets the position of the named directory stream to the beginning of the directory.
  public func rewind() throws {
    rewinddir(dir)
  }

  public func seek(offset: Int) throws {
    seekdir(dir, offset)
  }

  public var fd: FileDescriptor {
    .init(rawValue: dirfd(dir))
  }


  @available(*, deprecated, message: "unsafe")
  public func read(into entry: inout Directory.Entry) -> Result<Bool, Errno> {
    var entryPtr: UnsafeMutablePointer<dirent>?
    return nothingOrErrno(retryOnInterrupt: false) {
      readdir_r(dir, &entry.entry, &entryPtr)
    }
    .map { _ in
      if _slowPath(entryPtr == nil) {
        return false
      }
      withUnsafeMutablePointer(to: &entry) { ptr in
        assert(OpaquePointer(ptr) == OpaquePointer(entryPtr))
      }
      return true
    }
  }

  public func read() -> Result<UnsafeMutablePointer<Directory.Entry>?, Errno> {
    errno = 0
    let entry = readdir(dir)
    if entry == nil,
       case let err = Errno.current,
       err.rawValue != 0 {
      return .failure(err)
    }
    return .success(.init(OpaquePointer(entry)))
  }

  public func closeAfter<R>(_ body: (Self) throws -> R) throws -> R {
    defer { close() }
    return try body(self)
  }

}

extension dirent {
  var isDot: Bool {
    let point = UInt8(ascii: ".")
    return (d_name.0 == point && d_name.1 == 0)
    || (d_name.0 == point && d_name.1 == point && d_name.2 == 0)
  }
}

extension Directory {

  public struct Entry: CustomStringConvertible {

    fileprivate var entry: dirent

    public init() {
      entry = .init()
    }

    public var description: String {
      "DirectoryEntry(entryFileNumber: \(entryFileNumber), seekOffset: \(seekOffset), recordLength: \(recordLength), fileType: \(fileType), name: \"\(name)\")"
    }

    public var entryFileNumber: CInterop.UpInodeNumber {
      entry.d_ino
    }

    public var seekOffset: CInterop.UpSeekOffset {
      #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      return entry.d_seekoff
      #else
      return entry.d_off
      #endif
    }

    public var recordLength: UInt16 {
      entry.d_reclen
    }

    public var fileType: DirectoryType {
      DirectoryType(rawValue: entry.d_type)
    }

    public var isHidden: Bool {
      entry.d_name.0 == UInt8(ascii: ".")
    }

    /// is "." or ".."
    public var isDot: Bool {
      entry.isDot
    }

    @available(*, deprecated, renamed: "isDot")
    public var isInvalid: Bool {
      isDot
    }

    /// entry name (up to MAXPATHLEN bytes)
    public var name: String {
      #if canImport(Darwin)
      withNameBuffer { buffer in
        String(decoding: buffer, as: UTF8.self)
      }
      #else
      String(cStackString: entry.d_name)
      #endif
    }

    #if canImport(Darwin)
    public func withNameBuffer<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
      try withUnsafeBytes(of: entry.d_name) { buffer in
        try body(.init(rebasing: buffer.prefix(Int(entry.d_namlen))))
      }
    }
    #endif
  }

}

extension Directory {
  public struct DirectoryType: RawRepresentable, Equatable {

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
    default: return "unknown"
    }
  }

}

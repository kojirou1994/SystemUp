import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct RecursiveDirectoryReader {

  public struct ReadOptions: OptionSet {
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    public let rawValue: Int
  }

  public struct ReadResult {
    public let level: Int
    public let directory: Directory
    public let path: FilePath
    public let entry: Directory.Entry
  }

  public enum ReadContinuation {
    case `continue`
    case skipCurrentDirectory
    case cancel
  }

  public static func open(_ path: FilePath, body: (ReadResult) throws -> ReadContinuation, onOpenError: (FilePath, Errno) throws -> Void = { throw $1 }) throws {
    var isCancelled = false
    try _recursiveOpen(path, isCancelled: &isCancelled, level: 1, body: body, onError: onOpenError)
  }

  private static func _recursiveOpen(_ path: FilePath, isCancelled: inout Bool, level: Int, body: (ReadResult) throws -> ReadContinuation, onError: (FilePath, Errno) throws -> Void) throws {
//    if isCancelled {
//      return
//    }
    print(#function, path)
    let directory: Directory
    do {
      directory = try Directory.open(path)
    } catch let err as Errno {
      print("opendir error, call onError")
      return try onError(path, err)
    }

    try directory.closeAfter { directory in
      var entry = Directory.Entry()
      while try directory.read(into: &entry) {
        if entry.isInvalid {
          continue
        }
        let res = ReadResult(level: level, directory: directory, path: path.appending(entry.name), entry: entry)
        switch try body(res) {
        case .continue: break
        case .cancel:
          isCancelled = true
          return
        case .skipCurrentDirectory:
          return
        }

        if entry.fileType == .directory {
          try _recursiveOpen(res.path, isCancelled: &isCancelled, level: level+1, body: body, onError: onError)
        }

        if isCancelled {
          print("isCancelled! Exit from \(path)")
          return
        }
      }
    }
  }
}

public struct DirectoryEnumerator: Sequence {
  public init(root: FilePath, maxLevel: Int = .max) {
    self.maxLevel = maxLevel
    self.rootPath = root
  }

  public var maxLevel: Int
  public var rootPath: FilePath

  public __consuming func makeIterator() -> Iterator {
    .init(contents: self)
  }

  public final class Iterator: IteratorProtocol {
    internal init(contents: DirectoryEnumerator) {
      self.openedDirectories = []
      self.info = contents
    }

    private var openedDirectories: [(directory: Directory, path: FilePath)]
    private let info: DirectoryEnumerator
    private var started: Bool = false
    private var finished: Bool = false

    private var entry = Directory.Entry()

    public private(set) var error: Errno?

    private func push(_ path: FilePath) throws {
      if openedDirectories.count == info.maxLevel {
        // skip
        return
      }
      openedDirectories.append((try .open(path), path))
    }

    public func next() -> Element? {
      if finished {
        return nil
      }
      do {
        if _slowPath(!started) {
          try push(info.rootPath)
          started = true
        }
        while let lastDir = openedDirectories.last {

          while try lastDir.directory.read(into: &entry) {
            if entry.isInvalid {
              continue
            }
            let nextName = entry.name
            #warning("compiler bug")
            let nextPath = lastDir.path.appending(nextName)
            if entry.fileType == .directory {
              // push dir
              try push(nextPath)
            }
            return .init(level: openedDirectories.count, path: nextPath, entry: entry)
          }

          // last directory finished
          lastDir.directory.close()
          openedDirectories.removeLast()
        }
      } catch let err as Errno {
        // error happened
        self.error = err
      } catch {
        // no error
        fatalError()
      }
      finished = true
      return nil
    }

    deinit {
      openedDirectories.forEach { $0.directory.close() }
    }

    public struct Element {
      public let level: Int
      public let path: FilePath
      public let entry: Directory.Entry
    }

  }
}

public struct Directory {

  @_alwaysEmitIntoClient
  private init(dir: UnsafeMutablePointer<DIR>) {
    self.dir = dir
  }

  @_alwaysEmitIntoClient
  private let dir: UnsafeMutablePointer<DIR>

  @_alwaysEmitIntoClient
  public static func open(_ path: FilePath) throws -> Self {
    guard let dir = path.withPlatformString(opendir) else {
      throw Errno.current
    }
    return .init(dir: dir)
  }

  @_alwaysEmitIntoClient
  public static func open(_ fd: FileDescriptor) throws -> Self {
    guard let dir = fdopendir(fd.rawValue) else {
      throw Errno.current
    }
    return .init(dir: dir)
  }

  @_alwaysEmitIntoClient
  public func close() {
    if case .failure(let err) = nothingOrErrno(retryOnInterrupt: false, { closedir(dir) }) {
      // error is ignored
      assertionFailure("close dir failed: \(err)")
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

  @_alwaysEmitIntoClient
  public func read(into entry: inout Directory.Entry) throws -> Bool {
    var entryPtr: UnsafeMutablePointer<dirent>?
    try nothingOrErrno(retryOnInterrupt: false) {
      readdir_r(dir, &entry.entry, &entryPtr)
    }.get()
    if _slowPath(entryPtr == nil) {
      return false
    }
    withUnsafeMutablePointer(to: &entry) { ptr in
      assert(OpaquePointer(ptr) == OpaquePointer(entryPtr))
    }
    return true
  }

  public func read() throws -> UnsafeMutablePointer<Directory.Entry>? {
    let ptr = readdir(dir)
//    if ptr == nil, Errno.current != .init(rawValue: 0) {
//      throw Errno.current
//    }
    return .init(OpaquePointer(ptr))
  }

  @_alwaysEmitIntoClient
  public func closeAfter<R>(_ body: (Self) throws -> R) throws -> R {
    defer { close() }
    return try body(self)
  }

}

extension dirent {
  @_alwaysEmitIntoClient
  var isInvalid: Bool {
    let point = UInt8(ascii: ".")
    return (d_name.0 == point && d_name.1 == 0)
    || (d_name.0 == point && d_name.1 == point && d_name.2 == 0)
  }
}

extension Directory {

  public struct Entry: CustomStringConvertible {

    @_alwaysEmitIntoClient
    fileprivate var entry: dirent

    @_alwaysEmitIntoClient
    public init() {
      entry = .init()
    }

    public var description: String {
      "DirectoryEntry(entryFileNumber: \(entryFileNumber), seekOffset: \(seekOffset), recordLength: \(recordLength), fileType: \(fileType), name: \"\(name)\")"
    }

    @_alwaysEmitIntoClient
    public var entryFileNumber: UInt64 {
      entry.d_ino
    }

    @_alwaysEmitIntoClient
    public var seekOffset: UInt64 {
      entry.d_seekoff
    }

    @_alwaysEmitIntoClient
    public var recordLength: UInt16 {
      entry.d_reclen
    }

    @_alwaysEmitIntoClient
    public var fileType: DirectoryType {
      DirectoryType(rawValue: entry.d_type)
    }

    /// exclude "." and ".."
    @_alwaysEmitIntoClient
    public var isInvalid: Bool {
      entry.isInvalid
    }

    /// entry name (up to MAXPATHLEN bytes)
    @_alwaysEmitIntoClient
    public var name: String {
      #if canImport(Darwin)
      withUnsafeBytes(of: entry.d_name) { buffer in
        String(decoding: buffer.prefix(Int(entry.d_namlen)), as: UTF8.self)
      }
      #else
      String(cStackString: entry.d_name)
      #endif
    }
  }
}

extension Directory {
  public struct DirectoryType: RawRepresentable, Equatable {

    @_alwaysEmitIntoClient
    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }
    @_alwaysEmitIntoClient
    internal init(_ rawValue: Int32) {
      self.rawValue = .init(rawValue)
    }

    @_alwaysEmitIntoClient
    public let rawValue: UInt8
  }

}
extension Directory.DirectoryType {

  @_alwaysEmitIntoClient
  public static var unknown: Self { .init(DT_UNKNOWN) }

  @_alwaysEmitIntoClient
  public static var namedPipe: Self { .init(DT_FIFO) }

  @_alwaysEmitIntoClient
  public static var character: Self { .init(DT_CHR) }

  @_alwaysEmitIntoClient
  public static var directory: Self { .init(DT_DIR) }

  @_alwaysEmitIntoClient
  public static var block: Self { .init(DT_BLK) }

  @_alwaysEmitIntoClient
  public static var regular: Self { .init(DT_REG) }

  @_alwaysEmitIntoClient
  public static var symbolicLink: Self { .init(DT_LNK) }

  @_alwaysEmitIntoClient
  public static var socket: Self { .init(DT_SOCK) }

  @_alwaysEmitIntoClient
  public static var wht: Self { .init(DT_WHT) }

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
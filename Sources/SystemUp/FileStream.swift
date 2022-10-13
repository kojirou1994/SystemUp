import SystemLibc
import SystemPackage

public struct FileStream: RawRepresentable {

  public let rawValue: UnsafeMutablePointer<FILE>

  @inlinable @inline(__always)
  public init(rawValue: UnsafeMutablePointer<FILE>) {
    self.rawValue = rawValue
  }

}

// MARK: Open and Close
public extension FileStream {

  @inlinable @inline(__always)
  static func open(_ path: FilePath, mode: Mode) -> Result<Self, Errno> {
    syscallUnwrap {
      path.withPlatformString { path in
        SystemLibc.fopen(path, mode.rawValue)
      }
    }.map(Self.init)
  }

  @inlinable @inline(__always)
  static func open(_ fd: FileDescriptor, mode: Mode) -> Result<Self, Errno> {
    syscallUnwrap {
      SystemLibc.fdopen(fd.rawValue, mode.rawValue)
    }.map(Self.init)
  }

  @inlinable @inline(__always)
  static func open(_ buffer: UnsafeMutableRawBufferPointer, mode: Mode) -> Result<Self, Errno> {
    syscallUnwrap {
      SystemLibc.fmemopen(buffer.baseAddress, buffer.count, mode.rawValue)
    }.map(Self.init)
  }

  @inlinable @inline(__always)
  static func reopen(_ rawValue: Self, path: FilePath? = nil, mode: Mode) -> Result<Self, Errno> {
    let v: UnsafeMutablePointer<FILE>?
    if let path {
      v = path.withPlatformString { path in
        SystemLibc.freopen(path, mode.rawValue, rawValue.rawValue)
      }
    } else {
      v = SystemLibc.freopen(nil, mode.rawValue, rawValue.rawValue)
    }
    return syscallUnwrap { v }.map(Self.init)
  }

  @discardableResult
  @inlinable @inline(__always)
  func close() -> Result<Void, Errno> {
    voidOrErrno {
      SystemLibc.fclose(rawValue)
    }
  }

}

// MARK: check and reset stream status
public extension FileStream {
  @inlinable @inline(__always)
  func clearErrorIndicators() {
    SystemLibc.clearerr(rawValue)
  }

  @inlinable @inline(__always)
  var isEOF: Bool {
    SystemLibc.feof(rawValue) != 0
  }

  @inlinable @inline(__always)
  var isError: Bool {
    SystemLibc.ferror(rawValue) != 0
  }

  @inlinable @inline(__always)
  var fileDescriptor: FileDescriptor {
    .init(rawValue: SystemLibc.fileno(rawValue))
  }
}

// MARK: reposition a stream
public extension FileStream {

  @inlinable @inline(__always)
  func rewind() {
    neverError {
      voidOrErrno {
        SystemLibc.rewind(rawValue)
        return errno
      }
    }
  }

  @inlinable @inline(__always)
  func seek(toOffset offset: Int64, from origin: FileDescriptor.SeekOrigin) throws {
    try voidOrErrno {
      SystemLibc.fseeko(rawValue, offset, origin.rawValue)
    }.get()
  }

  @inlinable @inline(__always)
  func tell() -> Int64 {
    SystemLibc.ftello(rawValue)
  }

  @inlinable @inline(__always)
  var currentPosition: Int64 {
    set {
      withUnsafePointer(to: newValue) { pos in
        neverError {
          voidOrErrno {
            SystemLibc.fsetpos(rawValue, pos)
          }
        }
      }
    }
    get {
      var v: Int64 = 0
      neverError {
        voidOrErrno {
          SystemLibc.fgetpos(rawValue, &v)
        }
      }
      return v
    }
  }
}

// MARK: flush a stream
public extension FileStream {

  @discardableResult
  @inlinable @inline(__always)
  func flush() -> Result<Void, Errno> {
    voidOrErrno {
      SystemLibc.fflush(rawValue)
    }
  }

  @discardableResult
  @inlinable @inline(__always)
  static func flushAll() -> Result<Void, Errno> {
    voidOrErrno {
      SystemLibc.fflush(nil)
    }
  }
}

// MARK: binary stream input/output
public extension FileStream {
  @inlinable @inline(__always)
  func read(ptr: UnsafeMutableRawPointer, size: Int, count: Int) -> Int {
    SystemLibc.fread(ptr, size, count, rawValue)
  }

  @inlinable @inline(__always)
  func write(ptr: UnsafeMutableRawPointer, size: Int, count: Int) -> Int {
    SystemLibc.fwrite(ptr, size, count, rawValue)
  }
}

// MARK: character or word
public extension FileStream {
  @inlinable @inline(__always)
  func getc() -> Int32 {
    SystemLibc.getc(rawValue)
  }

  @inlinable @inline(__always)
  func getcUnlocked() -> Int32 {
    SystemLibc.getc_unlocked(rawValue)
  }

  @discardableResult
  @inlinable @inline(__always)
  func putc(_ char: Int32) -> Int32 {
    SystemLibc.putc(char, rawValue)
  }

  @discardableResult
  @inlinable @inline(__always)
  func putcUnlocked(_ char: Int32) -> Int32 {
    SystemLibc.putc_unlocked(char, rawValue)
  }

  @discardableResult
  @inlinable @inline(__always)
  func ungetc(_ char: Int32) -> Int32 {
    SystemLibc.ungetc(char, rawValue)
  }

  @inlinable
  func nextCharacter() -> UInt8? {
    let value = getc()
    if _slowPath(value == EOF) {
      return nil
    }
    assert(UInt8(value) == value)
    return .init(truncatingIfNeeded: value)
  }

  @inlinable @inline(__always)
  func put(character: UInt8) {
    putc(Int32(character))
  }

  @inlinable @inline(__always)
  func unget(character: UInt8) {
    ungetc(Int32(character))
  }
}

// MARK: line
public extension FileStream {
  @discardableResult
  @inlinable @inline(__always)
  func getLine(into buffer: UnsafeMutableBufferPointer<CChar>) -> Bool {
    let result = SystemLibc.fgets(buffer.baseAddress, numericCast(buffer.count), rawValue)
    assert(result == nil || result == buffer.baseAddress)
    return result != nil
  }

  @discardableResult
  @inlinable @inline(__always)
  func put(line: UnsafePointer<CChar>?) -> Int32? {
    let result = SystemLibc.fputs(line, rawValue)
    guard result != EOF else {
      return nil
    }
    return result
  }
}

// MARK: lock
public extension FileStream {
  @inlinable @inline(__always)
  func lock() {
    SystemLibc.flockfile(rawValue)
  }

  @inlinable @inline(__always)
  func tryLock() -> Bool {
    SystemLibc.ftrylockfile(rawValue) == 0
  }

  @inlinable @inline(__always)
  func unlock() {
    SystemLibc.funlockfile(rawValue)
  }
}

public extension FileStream {
  @inlinable @inline(__always)
  static var standardInput: FileStream {
    .init(rawValue: SystemLibc.stdin)
  }

  @inlinable @inline(__always)
  static var standardOutput: FileStream {
    .init(rawValue: SystemLibc.stdout)
  }

  @inlinable @inline(__always)
  static var standardError: FileStream {
    .init(rawValue: SystemLibc.stderr)
  }

  @inlinable @inline(__always)
  static func tempFile() -> Result<Self, Errno> {
    syscallUnwrap {
      SystemLibc.tmpfile()
    }.map(Self.init)
  }
}

extension FileStream {
  public struct Mode: RawRepresentable {
    public let rawValue: String
    @inlinable @inline(__always)
    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }
}

public extension FileStream.Mode {
  @inlinable @inline(__always)
  static func read(write: Bool = false, binary: Bool = false, closeOnExec: Bool = false) -> Self {
    var v = "r"
    if write {
      v += "+"
    }
    if binary {
      v += "b"
    }
    if closeOnExec {
      v += "e"
    }
    return .init(rawValue: v)
  }

  @inlinable @inline(__always)
  static func write(read: Bool = false, binary: Bool = false, exclusive: Bool = false, closeOnExec: Bool = false) -> Self {
    var v = "w"
    if read {
      v += "+"
    }
    if binary {
      v += "b"
    }
    if exclusive {
      v += "x"
    }
    if closeOnExec {
      v += "e"
    }
    return .init(rawValue: v)
  }

  @inlinable @inline(__always)
  static func append(read: Bool = false, binary: Bool = false, closeOnExec: Bool = false) -> Self {
    var v = "a"
    if read {
      v += "+"
    }
    if binary {
      v += "b"
    }
    if closeOnExec {
      v += "e"
    }
    return .init(rawValue: v)
  }
}

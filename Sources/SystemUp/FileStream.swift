import SystemLibc
import SystemPackage

public struct FileStream: RawRepresentable {

  public let rawValue: UnsafeMutablePointer<FILE>

  @inlinable @inline(__always)
  public init(rawValue: UnsafeMutablePointer<FILE>) {
    self.rawValue = rawValue
  }

}

extension FileStream {
  public struct Position: RawRepresentable {
    public var rawValue: fpos_t
    public init(rawValue: fpos_t) {
      self.rawValue = rawValue
    }
  }
}

// MARK: Open and Close
public extension FileStream {

  @inlinable @inline(__always)
  static func open(_ path: FilePath, mode: Mode) -> Result<Self, Errno> {
    SyscallUtilities.unwrap {
      path.withPlatformString { path in
        SystemLibc.fopen(path, mode.rawValue)
      }
    }.map(Self.init)
  }

  @inlinable @inline(__always)
  static func open(_ fd: FileDescriptor, mode: Mode) -> Result<Self, Errno> {
    SyscallUtilities.unwrap {
      SystemLibc.fdopen(fd.rawValue, mode.rawValue)
    }.map(Self.init)
  }

  @inlinable @inline(__always)
  static func open(_ buffer: UnsafeMutableRawBufferPointer, mode: Mode) -> Result<Self, Errno> {
    SyscallUtilities.unwrap {
      SystemLibc.fmemopen(buffer.baseAddress, buffer.count, mode.rawValue)
    }.map(Self.init)
  }

  @inlinable @inline(__always)
  static func reopen(_ rawValue: Self, path: FilePath? = nil, mode: Mode) -> Result<Self, Errno> {
    let v: UnsafeMutablePointer<FILE>?
    if let path = path {
      v = path.withPlatformString { path in
        SystemLibc.freopen(path, mode.rawValue, rawValue.rawValue)
      }
    } else {
      v = SystemLibc.freopen(nil, mode.rawValue, rawValue.rawValue)
    }
    return SyscallUtilities.unwrap { v }.map(Self.init)
  }

  @discardableResult
  @inlinable @inline(__always)
  func close() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
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
  func clearErrorIndicatorsUnlocked() {
    SystemLibc.swift_clearerr_unlocked(rawValue)
  }

  @inlinable @inline(__always)
  var isEOF: Bool {
    SystemLibc.feof(rawValue) != 0
  }

  @inlinable @inline(__always)
  var isEOFUnlocked: Bool {
    SystemLibc.swift_feof_unlocked(rawValue) != 0
  }

  @inlinable @inline(__always)
  var isError: Bool {
    SystemLibc.ferror(rawValue) != 0
  }

  @inlinable @inline(__always)
  var isErrorUnlocked: Bool {
    SystemLibc.swift_ferror_unlocked(rawValue) != 0
  }

  @inlinable @inline(__always)
  var fileDescriptor: FileDescriptor {
    .init(rawValue: SystemLibc.fileno(rawValue))
  }

  @inlinable @inline(__always)
  var fileDescriptorUnlocked: FileDescriptor {
    .init(rawValue: SystemLibc.swift_fileno_unlocked(rawValue))
  }
}

// MARK: reposition a stream
public extension FileStream {

  @inlinable @inline(__always)
  func rewind() {
    assertNoFailure {
      SyscallUtilities.voidOrErrno { () -> Int32 in
        SystemLibc.rewind(rawValue)
        return SystemLibc.errno
      }
    }
  }

  @inlinable @inline(__always)
  func seek(toOffset offset: Int, from origin: FileDescriptor.SeekOrigin) throws {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.fseek(rawValue, offset, origin.rawValue)
    }.get()
  }

  @inlinable @inline(__always)
  func tell() -> Int {
    SystemLibc.ftell(rawValue)
  }

  @inlinable @inline(__always)
  var currentPosition: Position {
    set {
      withUnsafePointer(to: newValue.rawValue) { pos in
        assertNoFailure {
          SyscallUtilities.voidOrErrno {
            SystemLibc.fsetpos(rawValue, pos)
          }
        }
      }
    }
    get {
      var v: Position = .init(rawValue: .init())
      assertNoFailure {
        SyscallUtilities.voidOrErrno {
          SystemLibc.fgetpos(rawValue, &v.rawValue)
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
    SyscallUtilities.voidOrErrno {
      SystemLibc.fflush(rawValue)
    }
  }

  @discardableResult
  @inlinable @inline(__always)
  static func flushAll() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
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
  func write(ptr: UnsafeRawPointer, size: Int, count: Int) -> Int {
    SystemLibc.fwrite(ptr, size, count, rawValue)
  }

  @inlinable @inline(__always)
  func read<T>(into buffer: UnsafeMutableBufferPointer<T>) -> Int {
    read(ptr: buffer.baseAddress!, size: MemoryLayout<T>.stride, count: buffer.count)
  }

  @inlinable @inline(__always)
  func write<T>(buffer: UnsafeBufferPointer<T>) -> Int {
    write(ptr: buffer.baseAddress!, size: MemoryLayout<T>.stride, count: buffer.count)
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
  func put(line: UnsafePointer<CChar>) -> Int32? {
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
    SyscallUtilities.unwrap {
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
  @_alwaysEmitIntoClient
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
  @_alwaysEmitIntoClient
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
  @_alwaysEmitIntoClient
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

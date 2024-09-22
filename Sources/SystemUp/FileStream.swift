import SystemLibc
import SystemPackage
import CGeneric
import CUtility

public struct FileStream: ~Copyable {

  @usableFromInline
  internal let rawValue: UnsafeMutablePointer<FILE>

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

// TODO: typed throws
// MARK: Open and Close
public extension FileStream {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func open(_ path: String, mode: Mode) throws(Errno) -> Self {
    try .init(rawValue: SyscallUtilities.unwrap {
      SystemLibc.fopen(path, mode.rawValue)
    }.get())
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func open(_ path: some CStringConvertible, mode: Mode) throws(Errno) -> Self {
    try .init(rawValue: SyscallUtilities.unwrap {
      path.withCString { path in
        SystemLibc.fopen(path, mode.rawValue)
      }
    }.get())
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func open(_ fd: FileDescriptor, mode: Mode) throws(Errno) -> Self {
    try .init(rawValue: SyscallUtilities.unwrap {
      SystemLibc.fdopen(fd.rawValue, mode.rawValue)
    }.get())
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func open(_ buffer: UnsafeMutableRawBufferPointer, mode: Mode) throws(Errno) -> Self {
    try .init(rawValue: SyscallUtilities.unwrap {
      SystemLibc.fmemopen(buffer.baseAddress, buffer.count, mode.rawValue)
    }.get())
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  borrowing func reopen(mode: Mode) throws(Errno) {
    let v = try SyscallUtilities.unwrap {
      SystemLibc.freopen(nil, mode.rawValue, rawValue)
    }.get()
    assert(v == rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  borrowing func reopen(_ path: String, mode: Mode) throws(Errno) {
    let v = try SyscallUtilities.unwrap {
      SystemLibc.freopen(path, mode.rawValue, rawValue)
    }.get()
    assert(v == rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  borrowing func reopen(_ path: some CStringConvertible, mode: Mode) throws(Errno) {
    let v = try SyscallUtilities.unwrap {
      path.withCString { path in
        SystemLibc.freopen(path, mode.rawValue, rawValue)
      }
    }.get()
    assert(v == rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func tempFile() throws(Errno) -> Self {
    try .init(rawValue: SyscallUtilities.unwrap {
      SystemLibc.tmpfile()
    }.get())
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  consuming func close() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.fclose(rawValue)
    }
  }

  @_alwaysEmitIntoClient
  consuming func closeAfter<R: ~Copyable, E: Error>(_ body: (borrowing Self) throws(E) -> R) throws(E) -> R {
    do {
      let result = try body(self)
      close()
      return result
    } catch {
      close()
      throw error
    }
  }
}

// MARK: check and reset stream status
public extension FileStream {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func clearErrorIndicators() {
    SystemLibc.clearerr(rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func clearErrorIndicatorsUnlocked() {
    SystemLibc.swift_clearerr_unlocked(rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var isEOF: Bool {
    SystemLibc.feof(rawValue) != 0
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var isEOFUnlocked: Bool {
    SystemLibc.swift_feof_unlocked(rawValue) != 0
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var isError: Bool {
    SystemLibc.ferror(rawValue) != 0
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var isErrorUnlocked: Bool {
    SystemLibc.swift_ferror_unlocked(rawValue) != 0
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var fileDescriptor: FileDescriptor {
    .init(rawValue: SystemLibc.fileno(rawValue))
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var fileDescriptorUnlocked: FileDescriptor {
    .init(rawValue: SystemLibc.swift_fileno_unlocked(rawValue))
  }
}

// MARK: reposition a stream
public extension FileStream {

  /// sets the file position indicator for the stream to the beginning of the file
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func rewind() {
    SystemLibc.rewind(rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func seek(toOffset offset: Int, from origin: FileDescriptor.SeekOrigin) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.fseek(rawValue, offset, origin.rawValue)
    }.get()
  }

  /// obtains the current value of the file position indicator for the stream
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func tell() -> Int {
    SystemLibc.ftell(rawValue)
  }

  /// alternate interfaces equivalent to tell() and seek()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var currentPosition: Position {
    nonmutating set {
      withUnsafePointer(to: newValue.rawValue) { pos in
        _ = assertNoFailure {
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
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func flush() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.fflush(rawValue)
    }
  }

  /// flushes all open output streams.
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func flushAll() -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      SystemLibc.fflush(nil)
    }
  }
}

// MARK: binary stream input/output
public extension FileStream {
  /// number of items read
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func read(into buffer: UnsafeMutableRawPointer, size: Int, count: Int) -> Int {
    SystemLibc.fread(buffer, size, count, rawValue)
  }

  /// number of items write
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func write(buffer: UnsafeRawPointer, size: Int, count: Int) -> Int {
    SystemLibc.fwrite(buffer, size, count, rawValue)
  }

  /// number of items read
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func read<T>(into buffer: UnsafeMutableBufferPointer<T>) -> Int {
    assert(MemoryLayout<T>.stride == MemoryLayout<T>.size, "T is not aligned!")
    return read(into: buffer.baseAddress!, size: MemoryLayout<T>.stride, count: buffer.count)
  }

  /// number of items write
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func write<T>(buffer: UnsafeBufferPointer<T>) -> Int {
    assert(MemoryLayout<T>.stride == MemoryLayout<T>.size, "T is not aligned!")
    return write(buffer: buffer.baseAddress!, size: MemoryLayout<T>.stride, count: buffer.count)
  }
}

// MARK: character or word
public extension FileStream {

  /// fgetc() reads the next character from stream and returns it as an unsigned char cast to an int, or EOF on end of file or error.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getc() -> Int32 {
    SystemLibc.getc(rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getcUnlocked() -> Int32 {
    SystemLibc.getc_unlocked(rawValue)
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func putc(_ char: Int32) -> Int32 {
    SystemLibc.putc(char, rawValue)
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func putcUnlocked(_ char: Int32) -> Int32 {
    SystemLibc.putc_unlocked(char, rawValue)
  }

  /// pushes c back to stream
  /// - Parameter char: cast to unsigned char
  /// - Returns: success
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func ungetc(_ char: Int32) -> Bool {
    let result = SystemLibc.ungetc(char, rawValue)
    // ungetc() returns c on success, or EOF on error.
    return result == char
  }

  // MARK: Wrappers

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func readByte() -> UInt8? {
    let value = getc()
    if _slowPath(value == SystemLibc.EOF) {
      return nil
    }
    assert(UInt8(value) == value)
    return .init(truncatingIfNeeded: value)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func write(byte: UInt8) {
    putc(Int32(byte))
  }

  /// pushes c back to stream, cast to unsigned char, where it is available for subsequent read operations.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func unget(byte: UInt8) {
    ungetc(Int32(byte))
  }
}

// MARK: line
public extension FileStream {
  /// reads in at most one less than size characters from stream and stores them into the buffer. Reading stops after an EOF or a newline. If a newline is read, it is stored into the buffer. A terminating null byte ('\0') is stored after the last character in the buffer.
  /// - Parameter buffer: dest buffer
  /// - Returns: success
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getLine(into buffer: UnsafeMutableBufferPointer<CChar>) -> Bool {
    let result = SystemLibc.fgets(buffer.baseAddress, numericCast(buffer.count), rawValue)
    // fgets() returns s on success, and NULL on error or when end of file occurs while no characters have been read.
    assert(result == nil || result == buffer.baseAddress)
    return result != nil
  }

  /// delimited string input
  /// - Parameters:
  ///   - line: output line buffer address, will be allocated if nil, remember to release it.If line was set to nil before the call, then the buffer should be freed by the user program even on failure.
  ///   - linecapp: capacity of line buffer
  ///   - delimiter: delimiter character
  /// - Returns: the number of characters read, including the delimiter character, but not including the terminating null byte, return nil if EOF.
  /// line is always non-nil on success.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getDelimitedLine(line: inout UnsafeMutablePointer<CChar>?, linecapp: inout Int, delimiter: UInt8 = .init(ascii: "\n")) throws(Errno) -> Int? {

    let result = SystemLibc.getline(&line, &linecapp, rawValue)

    if result == -1 {
      if _fastPath(isEOF) {
        return nil
      } else {
        throw Errno.systemCurrent
      }
    }

    assert(result > 0, "getline returns \(result)")
    assert(line != nil)

    return result
  }

  /// delimited string input
  /// - Parameter delimiter: delimiter character
  /// - Returns: string including the delimiter character. return nil if EOF.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getDelimitedLine(delimiter: UInt8 = .init(ascii: "\n")) throws(Errno) -> LazyCopiedCString? {
    var line: UnsafeMutablePointer<CChar>?
    var linecapp = 0
    guard let length = try getDelimitedLine(line: &line, linecapp: &linecapp, delimiter: delimiter) else {
      return nil
    }
    return .init(cString: line.unsafelyUnwrapped, forceLength: length, freeWhenDone: true)
  }

  // MARK: Wrappers

  /// iterate over delimited lines, error from getline() is ignored
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func iterateDelimitedLine<E: Error>(initialBufferSize: Int = 0, delimiter: UInt8 = .init(ascii: "\n"), strippingDelimiter: Bool = true, _ body: (_ line: borrowing DynamicCString, _ length: Int, _ stop: inout Bool) throws(E) -> Void) throws(E) {
    var capp = initialBufferSize
    var buf: UnsafeMutablePointer<CChar>?
    if capp > 0 {
      buf = .allocate(capacity: capp)
    }
    defer {
      buf?.deallocate()
    }
    var stop = false
    while !stop, case let length = SystemLibc.getline(&buf, &capp, rawValue),
            length > 0 {
      assert(buf != nil)
      let validStr = buf.unsafelyUnwrapped
      var validLength = length
      if strippingDelimiter {
        if validStr[length-1] == delimiter {
          validStr[length-1] = 0
          validLength -= 1
        }
      }
      let str = DynamicCString(cString: validStr)

      do {
        try body(str, validLength, &stop)
        _ = str.take()
      } catch {
        _ = str.take()
        throw error
      }
    }
  }
  /// writes the string to stream, without its terminating null byte ('\0').
  /// - Parameter string: null-terminated string
  /// - Returns: nonnegative number on success
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  @CStringGeneric()
  func write(_ string: String) -> Int32? {
    let result = SystemLibc.fputs(string, rawValue)
    if _slowPath(result == SystemLibc.EOF) {
      return nil
    }
    return result
  }
}

// MARK: lock
public extension FileStream {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func lock() {
    SystemLibc.flockfile(rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func tryLock() -> Bool {
    SystemLibc.ftrylockfile(rawValue) == 0
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func unlock() {
    SystemLibc.funlockfile(rawValue)
  }
}

// MARK: Standard Streams
public extension FileStream {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var standardInput: FileStream {
    .init(rawValue: SystemLibc.swift_get_stdin())
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var standardOutput: FileStream {
    .init(rawValue: SystemLibc.swift_get_stdout())
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var standardError: FileStream {
    .init(rawValue: SystemLibc.swift_get_stderr())
  }
}

extension FileStream {
  public struct Mode: RawRepresentable, ExpressibleByStringLiteral, Equatable {
    public let rawValue: String
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: String) {
      self.rawValue = rawValue
    }
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(stringLiteral value: String) {
      self.init(rawValue: value)
    }
  }
}

public extension FileStream.Mode {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
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

  @_alwaysEmitIntoClient @inlinable @inline(__always)
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

  @_alwaysEmitIntoClient @inlinable @inline(__always)
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

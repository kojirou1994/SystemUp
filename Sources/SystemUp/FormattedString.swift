import CUtility
import SystemLibc
import SystemPackage

@usableFromInline
internal func check(args: [CVarArg]) {
  #if DEBUG
  for arg in args {
    if arg is String {
      fatalError("String's conformance for CVarArg is from Foundation and it's bad for libc. Use withCString(_:) to pass C string.")
    }
  }
  #endif
}

public func withFixedCVarArgs<R>(_ args: [CVarArg], startIndex: Int = 0, _ body: ([CVarArg]) -> R) -> R {
  for index in startIndex..<args.count {
    let cStringHandler: (UnsafePointer<CChar>) -> R = { cString in
      // TODO: reduce copies
      var copy = args
      copy[index] = cString
      return withFixedCVarArgs(copy, startIndex: index+1, body)
    }
    if let string = args[index] as? String {
      return string.withCString(cStringHandler)
    }
  }
  return body(args)
}

// MARK: Output
public extension LazyCopiedCString {
  convenience init(format: UnsafePointer<CChar>, _ args: CVarArg...) throws {
    try self.init(format: format, arguments: args)
  }

  convenience init(format: UnsafePointer<CChar>, arguments: [CVarArg]) throws {
    check(args: arguments)
    var length: Int32 = 0
    let cString = try safeInitialize { str in
      withVaList(arguments) { va in
        length = SystemLibc.vasprintf(&str, format, va)
      }
    }
    self.init(cString: cString, forceLength: Int(length), freeWhenDone: true)
  }
}

public extension FileStream {
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func write(format: UnsafePointer<CChar>, _ args: CVarArg...) -> Int32 {
    write(format: format, arguments: args)
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func write(format: UnsafePointer<CChar>, arguments: [CVarArg]) -> Int32 {
    check(args: arguments)
    return withVaList(arguments) { va in
      SystemLibc.vfprintf(rawValue, format, va)
    }
  }
}

public extension FileDescriptor {
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func write(format: UnsafePointer<CChar>, _ args: CVarArg...) -> Int32 {
    write(format: format, arguments: args)
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func write(format: UnsafePointer<CChar>, arguments: [CVarArg]) -> Int32 {
    check(args: arguments)
    return withVaList(arguments) { va in
      SystemLibc.vdprintf(rawValue, format, va)
    }
  }
}

// MARK: Input
public enum InputFormatConversion {
  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func scan(_ stream: borrowing FileStream, format: UnsafePointer<CChar>, _ args: UnsafeMutableRawPointer...) -> Int32 {
    withVaList(args) { va in
      SystemLibc.vfscanf(stream.rawValue, format, va)
    }
  }

  @discardableResult
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func scan(_ string: UnsafePointer<CChar>, format: UnsafePointer<CChar>, _ args: UnsafeMutableRawPointer...) -> Int32 {
    withVaList(args) { va in
      SystemLibc.vsscanf(string, format, va)
    }
  }
}

extension UnsafeMutableRawPointer: CVarArg {
  public var _cVarArgEncoding: [Int] {
    OpaquePointer(self)._cVarArgEncoding
  }
}

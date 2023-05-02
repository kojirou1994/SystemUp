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

// MARK: Output
public extension LazyCopiedCString {
  convenience init(format: UnsafePointer<CChar>, _ args: CVarArg...) throws {
    check(args: args)
    var length: Int32 = 0
    let cString = try safeInitialize { str in
      withVaList(args) { va in
        length = SystemLibc.vasprintf(&str, format, va)
      }
    }
    self.init(cString: cString, forceLength: Int(length), freeWhenDone: true)
  }
}

public extension FileStream {
  @inlinable
  @discardableResult
  func write(format: UnsafePointer<CChar>, _ args: CVarArg...) -> Int32 {
    check(args: args)
    return withVaList(args) { va in
      SystemLibc.vfprintf(rawValue, format, va)
    }
  }
}

public extension FileDescriptor {
  @inlinable
  @discardableResult
  func write(format: UnsafePointer<CChar>, _ args: CVarArg...) -> Int32 {
    check(args: args)
    return withVaList(args) { va in
      SystemLibc.vdprintf(rawValue, format, va)
    }
  }
}

// MARK: Input
public enum InputFormatConversion {
  @discardableResult
  public static func scan(_ stream: FileStream, format: UnsafePointer<CChar>, _ args: UnsafeMutableRawPointer...) -> Int32 {
    withVaList(args) { va in
      SystemLibc.vfscanf(stream.rawValue, format, va)
    }
  }

  @discardableResult
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

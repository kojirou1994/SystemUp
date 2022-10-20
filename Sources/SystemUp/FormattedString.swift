import CUtility
import SystemLibc
import SystemPackage

public extension LazyCopiedCString {
  convenience init(format: UnsafePointer<CChar>, _ args: CVarArg...) throws {
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
  func write(format: UnsafePointer<CChar>, _ args: CVarArg...) -> Int32 {
    withVaList(args) { va in
      SystemLibc.vfprintf(rawValue, format, va)
    }
  }
}


public extension FileDescriptor {
  func write(format: UnsafePointer<CChar>, _ args: CVarArg...) -> Int32 {
    withVaList(args) { va in
      SystemLibc.vdprintf(rawValue, format, va)
    }
  }
}

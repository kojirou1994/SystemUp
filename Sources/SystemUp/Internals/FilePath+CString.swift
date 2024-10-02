import CUtility
import SystemPackage

extension FilePath: @retroactive CStringConvertible {
  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  public func withUnsafeCString<R, E>(_ body: (UnsafePointer<CChar>) throws(E) -> R) throws(E) -> R where E : Error, R : ~Copyable {
    try safeInitialize { (result: inout Result<R, E>?) in
      withCString { cString in
        result = .init { () throws(E) -> R in
          try body(cString)
        }
      }
    }.get()
  }
}

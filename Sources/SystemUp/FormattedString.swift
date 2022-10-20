import CUtility
import SystemLibc

#if os(Linux)
@_silgen_name("vasprintf")
private func vasprintf(_ ret: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, _ format: UnsafePointer<CChar>!, _ va: CVaListPointer) -> Int32
#endif

public extension LazyCopiedCString {
  convenience init(format: UnsafePointer<CChar>, _ args: CVarArg...) throws {
    var size: Int32 = 0
    let cString = try safeInitialize { str in
      withVaList(args) { va in
        size = vasprintf(&str, format, va)
      }
    }
    self.init(cString: cString, forceLength: Int(size), freeWhenDone: true)
  }
}

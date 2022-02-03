import CProc

public enum Proc { }

public extension Proc {

  static var libversion: (major: Int32, minor: Int32) {
    var v: (Int32, Int32) = (0, 0)
    proc_libversion(&v.0, &v.1)
    return v
  }
}

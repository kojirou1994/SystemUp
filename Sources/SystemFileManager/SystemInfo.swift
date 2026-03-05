import SystemUp
import CUtility

public enum SystemInfo {
  public static func hostname() throws(Errno) -> DynamicCString {
    let buf = try Memory.allocateZeroed(of: CChar.self, capacity: 255)
    do {
      try SystemCall.gethostname(into: buf)
    } catch {
      Memory.free(buf.baseAddress)
    }
    return .init(cString: buf.baseAddress!)
  }
}

#if os(Linux)
import XCTest
import SystemUp

final class GNULibcTests: XCTestCase {
  func testVersion() {
    print("GNU libc version: \(GNULibc.version.string)")
    print("GNU libc release: \(GNULibc.release.string)");
  }
}
#endif

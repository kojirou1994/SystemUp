import XCTest
import SystemUp
import SystemPackage

final class ErrnoTests: XCTestCase {
  func testErrno() {
    XCTAssertEqual(Foundation.errno, Errno.systemCurrent.rawValue)
    let expectedErrno = Errno.invalidArgument
    Errno.systemCurrent = expectedErrno
    XCTAssertEqual(Errno.systemCurrent, expectedErrno)
  }
}

import XCTest
import SystemUp

final class ErrnoTests: XCTestCase {
  func testErrno() {
    XCTAssertEqual(Foundation.errno, Errno.systemCurrent.rawValue)
    let expectedErrno = Errno.invalidArgument
    Errno.systemCurrent = expectedErrno
    XCTAssertEqual(Errno.systemCurrent, expectedErrno)
  }

  func testCopyMessage() throws {
    try withUnsafeTemporaryAllocation(of: CChar.self, capacity: 4096) { buf in
      for err in (0..<10).map(Errno.init) {
        XCTAssertNoThrow(try err.copyErrorMessage(to: buf))
      }

      XCTAssertThrowsError(try Errno(rawValue: .max).copyErrorMessage(to: buf)) { err in
        XCTAssertEqual(err as! Errno, .invalidArgument)
      }

    }
  }

  func testPrint() {
    Errno.print()
    Errno.systemCurrent = .noMemory
    Errno.print("no memory")
  }
}

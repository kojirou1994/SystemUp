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

  func testCopyMessage() throws {
    try withUnsafeTemporaryAllocation(of: CChar.self, capacity: 4096) { buf in
      for err in Errno.allCases {
        XCTAssertNoThrow(try err.copyErrorMessage(to: buf).get())
      }

      switch Errno(rawValue: .max).copyErrorMessage(to: buf) {
      case .success: XCTFail()
      case .failure(let err):
        XCTAssertEqual(err, .invalidArgument)
      }

    }
  }

  func testPrint() {
    Errno.print()
    Errno.systemCurrent = .noMemory
    Errno.print("no memory")
  }
}

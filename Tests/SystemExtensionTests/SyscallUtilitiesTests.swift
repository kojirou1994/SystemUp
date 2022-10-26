import XCTest
import SystemUp
import SystemPackage

final class SyscallUtilitiesTests: XCTestCase {

  func testSyscallUtilities() {

    let value: Int32 = .random(in: 1...Int32.max)
    let error = Errno.noMemory
    XCTAssertNoThrow(try SyscallUtilities.errnoOrZeroOnReturn({
      0
    }).get())

    XCTAssertThrowsError(try SyscallUtilities.errnoOrZeroOnReturn({
      error.rawValue
    }).get()) { catchedError in
      XCTAssertEqual(error, catchedError as? Errno)
    }

    XCTAssertNoThrow(try SyscallUtilities.valueOrErrno({
      value
    }).get())
    XCTAssertEqual(try! SyscallUtilities.valueOrErrno({
      value
    }).get(), value)

    XCTAssertThrowsError(try SyscallUtilities.valueOrErrno({
      Errno.systemCurrent = error
      return -1
    }).get()) { catchedError in
      XCTAssertEqual(error, catchedError as? Errno)
    }

    XCTAssertNoThrow(try SyscallUtilities.unwrap({
      value
    }).get())
    XCTAssertEqual(try! SyscallUtilities.unwrap({
      value
    }).get(), value)

    XCTAssertThrowsError(try SyscallUtilities.unwrap({
      Errno.systemCurrent = error
      return Optional<Int>.none
    }).get()) { catchedError in
      XCTAssertEqual(error, catchedError as? Errno)
    }
  }
}

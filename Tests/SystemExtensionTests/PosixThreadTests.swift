import XCTest
import SystemUp

final class PosixThreadTests: XCTestCase {

  func testEqual() {
    let t1 = PosixThread.current
    let t2 = PosixThread.current

    XCTAssertEqual(t1, t2)
  }

  func testThreadCreate() throws {
    var condition = false
    try PosixThread.detach {
      condition = true
    }

    Thread.sleep(forTimeInterval: 2)
    XCTAssertTrue(condition)

    condition = false
    let thread = try PosixThread.create(main: .init(main: {
      condition = true
    }))
    XCTAssertNoThrow(try thread.join().get())
    XCTAssertTrue(condition)
  }
}

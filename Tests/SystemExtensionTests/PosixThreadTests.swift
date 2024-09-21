import XCTest
import SystemUp

final class PosixThreadTests: XCTestCase {

  func testEqual() {
    let t1 = PosixThread.current
    let t2 = PosixThread.current

    XCTAssertTrue(t1.equals(to: t2))
  }

  func testThreadCreate() throws {
    var condition = false
    try PosixThread.detach {
      condition = true
    }

    Thread.sleep(forTimeInterval: 2)
    XCTAssertTrue(condition)

    condition = false
    let thread = try PosixThread.create {
      condition = true
    }
    _ = try thread.join().get()
    XCTAssertTrue(condition)
  }

  func testMutex() throws {
    nonisolated(unsafe) var mutex = try PosixMutex()
    defer {
      mutex.destroy()
    }
    nonisolated(unsafe) var value = 0
    let sum = 1_000_000
    DispatchQueue.concurrentPerform(iterations: sum) { _ in
      mutex.lock()
      value += 1
      mutex.unlock()
    }
    XCTAssertEqual(value, sum)
  }
}

import XCTest
import SystemUp

final class PosixThreadTests: XCTestCase {

  func testEqual() {
    let t1 = PosixThread.current
    let t2 = PosixThread.current

    XCTAssertTrue(t1.equals(to: t2))
  }

  func testThreadCreate() throws {
    nonisolated(unsafe) var condition = false
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
    let mutex = try PosixMutex()
    nonisolated(unsafe) var value = 0
    let sum = 1_000_000
    DispatchQueue.concurrentPerform(iterations: sum) { _ in
      mutex.lock()
      value += 1
      mutex.unlock()
    }
    XCTAssertEqual(value, sum)


    value = 0
    var threads = [PosixThread.ThreadID]()
    for _ in 1...10 {
      let tid = try PosixThread.create {
        for _ in 1...(sum/10) {
          mutex.lock()
          value += 1
          mutex.unlock()
        }
      }

      threads.append(tid)
    }
    threads.forEach { $0.join() }
    XCTAssertEqual(value, sum)
  }
}

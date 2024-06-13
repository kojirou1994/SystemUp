import XCTest
import SystemUp

final class WaitPIDTests: XCTestCase {

  func testExitStatus() {
    let status: CInt = 11
    var exit = WaitPID.ExitStatus.exited(status)
    XCTAssert(exit.exited)
    XCTAssertEqual(exit.exitStatus, status)

    let sig = Signal.abort
    exit = .signaled(sig)
    XCTAssert(exit.signaled)
    XCTAssertEqual(exit.terminationSignal, sig)

    exit = .stopped(sig)
    XCTAssert(exit.stopped)
    XCTAssertEqual(exit.stopSignal, sig)
  }
}

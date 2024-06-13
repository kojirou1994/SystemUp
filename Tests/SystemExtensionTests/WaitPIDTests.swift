import XCTest
import SystemUp

final class WaitPIDTests: XCTestCase {

  func testExitStatus() {
    let status: CInt = 11
    var exit = WaitPID.ExitStatus.exited(exitStatus: status)
    XCTAssert(exit.exited)
    XCTAssertEqual(exit.exitStatus, status)

    let sig = Signal.abort
    exit = .signaled(signal: sig)
    XCTAssert(exit.signaled)
    XCTAssertEqual(exit.terminationSignal, sig)

    exit = .stopped(signal: sig)
    XCTAssert(exit.stopped)
    XCTAssertEqual(exit.stopSignal, sig)
  }
}

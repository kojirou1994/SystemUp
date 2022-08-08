import XCTest
import SystemUp

final class PosixEnvironmentTests: XCTestCase {

  func testEnvironParsing() {
    XCTAssertEqual(ProcessInfo.processInfo.environment, PosixEnvironment.global.environment)
    measure {
      _ = PosixEnvironment.global
    }
  }

  func testGlobalAPI() {
    let key = "SYSTEM_ENV_TEST_KEY"
    let value = "1111"
    let differentValue = "2222"

    XCTAssertNotEqual(value, differentValue)

    XCTAssertNoThrow(try PosixEnvironment.set(key: key, value: value, overwrite: false).get())
    XCTAssertEqual(PosixEnvironment.get(key: key), value)

    XCTAssertNoThrow(try PosixEnvironment.set(key: key, value: value, overwrite: false).get())

    XCTAssertNoThrow(try PosixEnvironment.set(key: key, value: differentValue, overwrite: false).get())
    XCTAssertEqual(PosixEnvironment.get(key: key), value)

    XCTAssertNoThrow(try PosixEnvironment.set(key: key, value: differentValue, overwrite: true).get())
    XCTAssertEqual(PosixEnvironment.get(key: key), differentValue)

    XCTAssertNoThrow(try PosixEnvironment.unset(key: key).get())
    XCTAssertEqual(PosixEnvironment.get(key: key), nil)
  }
}

import XCTest
import SystemUp

final class FileStreamTests: XCTestCase {

  func testMode() {
    // ref: https://www.ibm.com/docs/en/zos/2.5.0?topic=functions-fopen-open-file
    XCTAssertEqual(FileStream.Mode.read(), "r")
    XCTAssertEqual(FileStream.Mode.read(write: true), "r+")
    XCTAssertEqual(FileStream.Mode.read(binary: true), "rb")
    XCTAssertEqual(FileStream.Mode.read(write: true, binary: true), "r+b")

    XCTAssertEqual(FileStream.Mode.write(), "w")
    XCTAssertEqual(FileStream.Mode.write(read: true), "w+")
    XCTAssertEqual(FileStream.Mode.write(binary: true), "wb")
    XCTAssertEqual(FileStream.Mode.write(read: true, binary: true), "w+b")

    XCTAssertEqual(FileStream.Mode.append(), "a")
    XCTAssertEqual(FileStream.Mode.append(read: true), "a+")
    XCTAssertEqual(FileStream.Mode.append(binary: true), "ab")
    XCTAssertEqual(FileStream.Mode.append(read: true, binary: true), "a+b")
  }

}

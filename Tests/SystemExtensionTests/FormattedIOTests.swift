import XCTest
import SystemUp

final class FormattedIOTests: XCTestCase {

  func testInput() throws {
    let input = "HELLO_123_WORLD_456"
    let format = "HELLO_%d_WORLD_%d"

    // string input
    do {
      var v1: CInt = 0
      var v2: CInt = 0
      XCTAssertEqual(InputFormatConversion.scan(input, format: format, &v1, &v2), 2)
      XCTAssertEqual(v1, 123)
      XCTAssertEqual(v2, 456)
    }

    // stream input
    var inputBuffer = Data(input.utf8)
    try inputBuffer.withUnsafeMutableBytes { buffer in
      let stream = try FileStream.open(buffer, mode: .read())

      var v1: CInt = 0
      var v2: CInt = 0
      XCTAssertEqual(InputFormatConversion.scan(stream, format: format, &v1, &v2), 2)
      XCTAssertEqual(v1, 123)
      XCTAssertEqual(v2, 456)
    }
  }
}

import XCTest
import SystemUp
import CUtility

final class CStringArrayTests: XCTestCase {
  let swiftArray = [String](repeating: "ABCD👌", count: 20)

  func testStructured() {
    let cArray = CStringArray(swiftArray)
    cArray.withUnsafeCArrayPointer { start in
      XCTAssertEqual(NullTerminatedArray(start).map { String(cString: $0.pointee) }, swiftArray)
    }
  }

  func testDynamicArray() throws {
    var cArray = CStringArray()
    for _ in 1...10 {
      cArray.append(try CStringUtils.copy("ABCD👌"))
    }
    cArray.append(contentsOf: repeatElement("ABCD👌", count: 10))
    cArray.withUnsafeCArrayPointer { start in
      XCTAssertEqual(NullTerminatedArray(start).map { String(cString: $0.pointee) }, swiftArray)
    }
  }

  func testTemp() {
    withTempUnsafeCStringArray(swiftArray) { start in
      XCTAssertEqual(NullTerminatedArray(start).map { String(cString: $0.pointee) }, swiftArray)
    }
  }
}

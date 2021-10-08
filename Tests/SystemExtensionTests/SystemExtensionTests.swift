import XCTest
import SystemPackage
import SystemUp
import Foundation

final class SystemExtensionTests: XCTestCase {
  func testCWD() {
    let old = FileUtility.currentDirectoryPath

    XCTAssertNoThrow(try FileUtility.changeCurrentDirectoryPath(".."))

    let new = FileUtility.currentDirectoryPath

    XCTAssertEqual(old.removingLastComponent(), new)
  }
}

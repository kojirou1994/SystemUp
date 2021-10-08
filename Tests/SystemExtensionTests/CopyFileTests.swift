import XCTest
import SystemPackage
import SystemUp

final class CopyFileTests: XCTestCase {
  func testCopyFileFlags() {
    XCTAssertEqual([CopyFlags.nofollowDst, .nofollowSrc] as CopyFlags, CopyFlags.nofollow)

    XCTAssertEqual([CopyFlags.stat, .acl] as CopyFlags, CopyFlags.security)

    XCTAssertEqual([CopyFlags.security, .xattr] as CopyFlags, CopyFlags.metadata)

    XCTAssertEqual([CopyFlags.metadata, .data] as CopyFlags, CopyFlags.all)
  }
}

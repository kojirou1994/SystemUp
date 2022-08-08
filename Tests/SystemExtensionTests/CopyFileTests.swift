#if canImport(Darwin)
import XCTest
import SystemPackage
import SystemUp

final class CopyFileTests: XCTestCase {
  func testCopyFileFlags() {
    XCTAssertEqual([CopyFlags.noFollowDestination, .noFollowSource] as CopyFlags, CopyFlags.noFollow)

    XCTAssertEqual([CopyFlags.stat, .acl] as CopyFlags, CopyFlags.security)

    XCTAssertEqual([CopyFlags.security, .xattr] as CopyFlags, CopyFlags.metadata)

    XCTAssertEqual([CopyFlags.metadata, .data] as CopyFlags, CopyFlags.all)
  }
}
#endif

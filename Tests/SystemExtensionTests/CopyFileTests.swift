#if canImport(Darwin)
import XCTest
import SystemUp
import CUtility

final class CopyFileTests: XCTestCase {
  func testCopyFileFlags() {
    XCTAssertEqual([SystemCall.CopyFile.Flags.noFollowDestination, .noFollowSource] as SystemCall.CopyFile.Flags, SystemCall.CopyFile.Flags.noFollow)

    XCTAssertEqual([SystemCall.CopyFile.Flags.stat, .acl] as SystemCall.CopyFile.Flags, SystemCall.CopyFile.Flags.security)

    XCTAssertEqual([SystemCall.CopyFile.Flags.security, .xattr] as SystemCall.CopyFile.Flags, SystemCall.CopyFile.Flags.metadata)

    XCTAssertEqual([SystemCall.CopyFile.Flags.metadata, .data] as SystemCall.CopyFile.Flags, SystemCall.CopyFile.Flags.all)
  }

}
#endif

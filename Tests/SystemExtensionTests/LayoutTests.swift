import XCTest
import SystemUp
import SystemLibc
import CUtility

final class LayoutTests: XCTestCase {
  func check<L, R>(_ l: L.Type, r: R.Type) {
    XCTAssertEqual(MemoryLayout<L>.size, MemoryLayout<R>.size)
    XCTAssertEqual(MemoryLayout<L>.stride, MemoryLayout<R>.stride)
  }

  func testCastedTypes() {
    // assumingMemoryBound used types
    check(SocketAddress.IPV4.self, r: sockaddr_in.self)
    check(SocketAddress.IPV6.self, r: sockaddr_in6.self)
    check(SocketAddress.Unix.self, r: sockaddr_un.self)
    #if canImport(Darwin)
    check(Kqueue.Kevent.self, r: kevent.self)
    check(Kqueue.Kevent64.self, r: kevent64_s.self)
    #endif
    check(SocketAddressInfo.self, r: addrinfo.self)
    check(SystemCall.PollFD.self, r: pollfd.self)
    check(StaticCString.self, r: UnsafePointer<CChar>.self)
  }
}

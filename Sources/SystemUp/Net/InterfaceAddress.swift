import SystemLibc
import SystemPackage
import CUtility

public struct InterfaceAddressList: ~Copyable {
  @usableFromInline
  internal let rawAddress: UnsafeMutablePointer<ifaddrs>

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init() throws(Errno) {
    rawAddress = try safeInitialize { temp throws(Errno) in
      try SyscallUtilities.voidOrErrno {
        getifaddrs(&temp)
      }.get()
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    freeifaddrs(rawAddress)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func iterate<E: Error>(_ body: (_ address: borrowing InterfaceAddress, _ stop: inout Bool) throws(E) -> Void) throws(E) {
    var current = rawAddress
    var stop = false
    while !stop {
      try body(.init(ptr: current), &stop)
      guard let next = current.pointee.ifa_next else {
        return
      }
      current = next
    }
  }

}

public struct InterfaceAddress: ~Copyable {
  @_alwaysEmitIntoClient
  internal init(ptr: UnsafeMutablePointer<ifaddrs>) {
    self.ptr = ptr
  }

  @usableFromInline
  internal let ptr: UnsafeMutablePointer<ifaddrs>

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public var name: String {
    .init(cString: ptr.pointee.ifa_name)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func withNameCString<R: ~Copyable, E: Error>(_ body: (borrowing DynamicCString) throws(E) -> R) throws(E) -> R {
    try DynamicCString.withTemporaryBorrowed(cString: ptr.pointee.ifa_name, body)
  }

/*

 public var ifa_netmask: UnsafeMutablePointer<sockaddr>!

 public var ifa_dstaddr: UnsafeMutablePointer<sockaddr>!

 public var ifa_data: UnsafeMutableRawPointer!
 */

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var flags: UInt32 {
    ptr.pointee.ifa_flags
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public var family: AddressFamily {
    .init(rawValue: ptr.pointee.ifa_addr.pointee.sa_family)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func withSocketAddress<R: ~Copyable, E: Error>(_ body: (borrowing SocketAddress) throws(E) -> R) throws(E) -> R? {
    /*
     The ifa_addr field points to a structure containing the interface
     address.  (The sa_family subfield should be consulted to
     determine the format of the address structure.)  This field may
     contain a null pointer.
     */
    guard let addr = ptr.pointee.ifa_addr else {
      return nil
    }
    return try body(.init(addr))
  }
}


/// generic socket address API type
public struct SocketAddress: ~Copyable {

  @usableFromInline
  internal let rawAddress: UnsafeMutablePointer<sockaddr>

  @_alwaysEmitIntoClient
  internal init(_ rawAddress: UnsafeMutablePointer<sockaddr>) {
    self.rawAddress = rawAddress
  }

  @_alwaysEmitIntoClient
  internal init(_ rawAddress: UnsafeMutableRawPointer) {
    self.rawAddress = rawAddress.assumingMemoryBound(to: sockaddr.self)
  }

  #if canImport(Darwin)
  /// total length
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public var length: UInt8 {
    rawAddress.pointee.sa_len
  }
  #endif

  /// address family
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public var addressFamily: AddressFamily {
    get { .init(rawValue: rawAddress.pointee.sa_family) }
    set { rawAddress.pointee.sa_family = sa_family_t(newValue.rawValue) }
  }

  public struct IPV4 {
    @usableFromInline
    internal var rawValue: sockaddr_in
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init() {
      self.rawValue = .init()
      rawValue.sin_family = sa_family_t(AF_INET)
#if canImport(Darwin)
      rawValue.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.stride)
#endif
    }
  }

  public struct IPV6 {
    @usableFromInline
    internal var rawValue: sockaddr_in6
  }

  public struct Unix {
    @usableFromInline
    internal var rawValue: sockaddr_un
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func withTempGenericBuf<R: ~Copyable, E: Error>(_ body: (inout SocketAddress, _ length: UInt32) throws(E) -> R) throws(E) -> R {
    try toTypedThrows(E.self) {
      try withUnsafeTemporaryAllocation(of: sockaddr_storage.self, capacity: 1) { buf in
        var addr = SocketAddress(buf.baseAddress!)
        let length = socklen_t(MemoryLayout<sockaddr_storage>.size)
        return try body(&addr, length)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func asIPV4<R: ~Copyable, E: Error>(_ body: (IPV4) throws(E) -> R) throws(E) -> R {
    assert(addressFamily == .inet)
    return try body(UnsafeRawPointer(rawAddress).assumingMemoryBound(to: IPV4.self).pointee)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func asIPV6<R: ~Copyable, E: Error>(_ body: (IPV6) throws(E) -> R) throws(E) -> R {
    assert(addressFamily == .inet6)
    return try body(UnsafeRawPointer(rawAddress).assumingMemoryBound(to: IPV6.self).pointee)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func asUnix<R: ~Copyable, E: Error>(_ body: (Unix) throws(E) -> R) throws(E) -> R {
    assert(addressFamily == .unix)
    return try body(UnsafeRawPointer(rawAddress).assumingMemoryBound(to: Unix.self).pointee)
  }

}

public extension SocketAddress.IPV4 {

  #if canImport(Darwin)
  /// total length
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var length: UInt8 {
    rawValue.sin_len
  }
  #endif

  /// address family
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var addressFamily: AddressFamily {
    assert(rawValue.sin_family == AF_INET)
    return .init(rawValue: rawValue.sin_family)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var port: NetworkByteOrderInteger<UInt16> {
    get { .init(rawValue.sin_port) }
    set { rawValue.sin_port = newValue.value }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var address: InternetAddress {
    get { .init(rawValue: rawValue.sin_addr) }
    set { rawValue.sin_addr = newValue.rawValue }
  }
}

public extension SocketAddress.IPV6 {

  #if canImport(Darwin)
  /// total length
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var length: UInt8 {
    rawValue.sin6_len
  }
  #endif

  /// address family
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var addressFamily: AddressFamily {
    assert(rawValue.sin6_family == AF_INET6)
    return .init(rawValue: rawValue.sin6_family)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var port: NetworkByteOrderInteger<UInt16> {
    .init(rawValue.sin6_port)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var flowinfo: UInt32 {
    rawValue.sin6_flowinfo
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var address: InternetAddress6 {
    .init(rawValue: rawValue.sin6_addr)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var scopeID: UInt32 {
    rawValue.sin6_scope_id
  }
}

public extension SocketAddress.Unix {

  #if canImport(Darwin)
  /// total length
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var length: UInt8 {
    rawValue.sun_len
  }
  #endif

  /// address family
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var addressFamily: AddressFamily {
    assert(rawValue.sun_family == AF_UNIX)
    return .init(rawValue: rawValue.sun_family)
  }
}

public extension SocketAddress.IPV4 {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func asSocket<R: ~Copyable, E: Error>(_ body: (borrowing SocketAddress, _ length: UInt32) throws(E) -> R) throws(E) -> R {
    try body(.init(&rawValue), UInt32((MemoryLayout<sockaddr_in>.size)))
  }
}

public extension SocketAddress.IPV6 {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func asSocket<R: ~Copyable, E: Error>(_ body: (borrowing SocketAddress, _ length: UInt32) throws(E) -> R) throws(E) -> R {
    try body(.init(&rawValue), UInt32((MemoryLayout<sockaddr_in6>.size)))
  }
}

public extension SocketAddress.Unix {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  mutating func asSocket<R: ~Copyable, E: Error>(_ body: (borrowing SocketAddress, _ length: UInt32) throws(E) -> R) throws(E) -> R {
    try body(.init(&rawValue), UInt32((MemoryLayout<sockaddr_un>.size)))
  }
}

public struct AddressFamily: Hashable {
  public let rawValue: sa_family_t

  @_alwaysEmitIntoClient
  internal init(rawValue: sa_family_t) {
    self.rawValue = rawValue
  }

  @_alwaysEmitIntoClient
  internal init(rawValue: Int32) {
    self.rawValue = numericCast(rawValue)
  }

  @_alwaysEmitIntoClient
  public static var unspecified: Self { .init(rawValue: SystemLibc.AF_UNSPEC) }
  @_alwaysEmitIntoClient
  public static var unix: Self { .init(rawValue: SystemLibc.AF_UNIX) }
  @_alwaysEmitIntoClient
  public static var local: Self { .init(rawValue: SystemLibc.AF_LOCAL) }
  @_alwaysEmitIntoClient
  public static var inet: Self { .init(rawValue: SystemLibc.AF_INET) }
  @_alwaysEmitIntoClient
  public static var inet6: Self { .init(rawValue: SystemLibc.AF_INET6) }
}

public extension SocketAddress {

  struct GetNameInfoFlags: MacroRawRepresentable, OptionSet {
    public var rawValue: Int32

    @_alwaysEmitIntoClient
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var noFullyQualifiedDomainName: Self { .init(macroValue: SystemLibc.NI_NOFQDN) }
    @_alwaysEmitIntoClient
    public static var numericFormHost: Self { .init(macroValue: SystemLibc.NI_NUMERICHOST) }
    @_alwaysEmitIntoClient
    public static var nameRequired: Self { .init(macroValue: SystemLibc.NI_NAMEREQD) }
    @_alwaysEmitIntoClient
    public static var numericFormService: Self { .init(macroValue: SystemLibc.NI_NUMERICSERV) }

    #if canImport(Darwin) || os(FreeBSD)
    @_alwaysEmitIntoClient
    public static var numericScope: Self { .init(macroValue: SystemLibc.NI_NUMERICSCOPE) }
    @_alwaysEmitIntoClient
    public static var withScopeID: Self { .init(macroValue: SystemLibc.NI_WITHSCOPEID) }
    #endif

    @_alwaysEmitIntoClient
    public static var datagramBasedService: Self { .init(macroValue: SystemLibc.NI_DGRAM) }

    @_alwaysEmitIntoClient
    public static var maxHostLength: Int32 { NI_MAXHOST }
    @_alwaysEmitIntoClient
    public static var maxServiceLength: Int32 { NI_MAXSERV }
  }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getnameinfo(host: UnsafeMutableBufferPointer<CChar>, serv: UnsafeMutableBufferPointer<CChar>, flags: GetNameInfoFlags) throws(Errno) {
    try getnameinfo(length: UInt32(self.length), host: host, serv: serv, flags: flags)
  }
  #endif

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func getnameinfo(length: UInt32, host: UnsafeMutableBufferPointer<CChar>, serv: UnsafeMutableBufferPointer<CChar>, flags: GetNameInfoFlags) throws(Errno) {
    try SyscallUtilities.errnoOrZeroOnReturn {
      SystemLibc.getnameinfo(rawAddress, length, host.baseAddress, socklen_t(host.count), serv.baseAddress, socklen_t(serv.count), flags.rawValue)
    }.get()
  }
}

public struct GetAddressInfoError: Error {
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  public var errorMessage: StaticCString {
    .init(cString: SystemLibc.gai_strerror(rawValue))
  }
}

/// IPv4 address
public struct InternetAddress: RawRepresentable, Hashable, BitwiseCopyable {

  public static func == (lhs: InternetAddress, rhs: InternetAddress) -> Bool {
    lhs.rawValue.s_addr == rhs.rawValue.s_addr
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue.s_addr)
  }

  public var rawValue: in_addr

  @_alwaysEmitIntoClient
  public init(rawValue: in_addr) {
    self.rawValue = rawValue
  }

//  public init(_ rawValue: NetworkByteOrderInteger<UInt32>) {
//    self.rawValue = .init(s_addr: rawValue.value)
//  }

  @_alwaysEmitIntoClient
  public init(_ a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) {
    let bigEndian = (UInt32(d) << 24) | (UInt32(c) << 16) | (UInt32(b) << 8) | UInt32(a)
    self.rawValue = .init(s_addr: bigEndian)
  }
}

public extension InternetAddress {
  @_alwaysEmitIntoClient
  static var any: Self { .init(rawValue: .init(s_addr: INADDR_ANY)) }
  @_alwaysEmitIntoClient
  static var broadcast: Self { .init(rawValue: .init(s_addr: INADDR_BROADCAST)) }
  @_alwaysEmitIntoClient
  static var loopback: Self { .init(rawValue: .init(s_addr: INADDR_LOOPBACK)) }
}

/// IPv6 address
public struct InternetAddress6: RawRepresentable {
  public var rawValue: in6_addr

  @_alwaysEmitIntoClient
  public init(rawValue: in6_addr) {
    self.rawValue = rawValue
  }
}

/// inet_lnaof(), inet_netof(), and inet_makeaddr() are legacy functions that assume they are dealing with classful network addresses.
public extension InternetAddress {

  /// machine byte order
  init(networkNumber: UInt32, localNetworkAddress: UInt32) {
    rawValue = inet_makeaddr(networkNumber, localNetworkAddress)
  }

  /// machine byte order
  var localNetworkAddress: UInt32 {
    inet_lnaof(rawValue)
  }

  /// machine byte order
  var networkNumber: UInt32 {
    inet_netof(rawValue)
  }
}

public extension InternetAddress {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var stringLength: Int {
    Int(INET_ADDRSTRLEN)
  }

  @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
  var string: String {
    .init(unsafeUninitializedCapacity: stringLength) { buffer in
//      try! assertNoThrow {
        try! buffer.withMemoryRebound(to: CChar.self) { buffer in
          try InetConvertion.NetworkByteOrder.convert(self, to: buffer)
        }
//      }

      return strlen(buffer.baseAddress!)
    }
  }
}

public extension InternetAddress6 {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var stringLength: Int {
    Int(INET6_ADDRSTRLEN)
  }

  @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
  var string: String {
    .init(unsafeUninitializedCapacity: stringLength) { buffer in
//      try! assertNoThrow {
        try! buffer.withMemoryRebound(to: CChar.self) { buffer in
          try InetConvertion.NetworkByteOrder.convert(self, to: buffer)
        }
//      }

      return strlen(buffer.baseAddress!)
    }
  }
}

public enum InetConvertion {
  public enum NetworkByteOrder {}
  public enum HostByteOrder {}
}

public extension InetConvertion {
//  @_alwaysEmitIntoClient @inlinable @inline(__always)
//  static func host2Network(_ v: UInt16) -> UInt16 {
//    swift_hton_u16_to_u16(v)
//  }
//
//  @_alwaysEmitIntoClient @inlinable @inline(__always)
//  static func host2Network(_ v: UInt32) -> UInt32 {
//    swift_hton_u32_to_u32(v)
//  }
//
//  @_alwaysEmitIntoClient @inlinable @inline(__always)
//  static func host2Network(_ v: UInt64) -> UInt64 {
//    swift_hton_u64_to_u64(v)
//  }
//
//  @_alwaysEmitIntoClient @inlinable @inline(__always)
//  static func network2Host(_ v: UInt16) -> UInt16 {
//    swift_ntoh_u16_to_u16(v)
//  }
//
//  @_alwaysEmitIntoClient @inlinable @inline(__always)
//  static func network2Host(_ v: UInt32) -> UInt32 {
//    swift_ntoh_u32_to_u32(v)
//  }
//
//  @_alwaysEmitIntoClient @inlinable @inline(__always)
//  static func network2Host(_ v: UInt64) -> UInt64 {
//    swift_ntoh_u64_to_u64(v)
//  }
}

public extension InetConvertion.HostByteOrder {
  /// return nil when invalid
  static func string2NetworkNumber(_ v: UnsafePointer<CChar>) -> UInt32? {
    let v = inet_network(v)
    if v == SystemLibc.INADDR_NONE {
      return nil
    }
    return v
  }
}

public extension InetConvertion.NetworkByteOrder {

  /// The string is returned in a statically allocated buffer, which subsequent calls will overwrite.
  static func address2StringStatic(_ v: InternetAddress) -> StaticCString {
    .init(cString: inet_ntoa(v.rawValue))
  }

  /// return nil when invalid
  static func string2Address(_ v: UnsafePointer<CChar>) -> InternetAddress? {
    let v = inet_addr(v)
    if v == SystemLibc.INADDR_NONE {
      return nil
    }
    return .init(rawValue: .init(s_addr: v))
  }

  static func string2Address(_ v: UnsafePointer<CChar>, dst: UnsafeMutablePointer<InternetAddress>) -> Bool {
    switch inet_aton(v, dst.pointer(to: \.rawValue)!) {
    case 1: return true
    case 0: return false
    default:
      assertionFailure("not posix std!")
      return false
    }
  }

  static func convert(_ address: InternetAddress, to dst: UnsafeMutableBufferPointer<CChar>) throws(Errno) {
    try toTypedThrows(Errno.self) {
      try withUnsafeBytes(of: address) { address in
        try convertGeneric(family: .inet, address: address.baseAddress.unsafelyUnwrapped, to: dst)
      }
    }
  }

  static func convert(_ address: InternetAddress6, to dst: UnsafeMutableBufferPointer<CChar>) throws(Errno) {
    try toTypedThrows(Errno.self) {
      try withUnsafeBytes(of: address) { address in
        try convertGeneric(family: .inet6, address: address.baseAddress.unsafelyUnwrapped, to: dst)
      }
    }
  }

  static func convertGeneric(family: AddressFamily, address: UnsafeRawPointer, to dst: UnsafeMutableBufferPointer<CChar>) throws(Errno) {
    switch family {
    case .inet: assert(dst.count >= INET_ADDRSTRLEN)
    case .inet6: assert(dst.count >= INET6_ADDRSTRLEN)
    default: break
    }
    try SyscallUtilities.unwrap {
      inet_ntop(Int32(family.rawValue), address, dst.baseAddress, socklen_t(dst.count))
    }.map{ assert($0 == dst.baseAddress!, "pointer changed?"); return () }
      .get()
  }

  static func convert(_ string: UnsafePointer<CChar>, to dst: inout InternetAddress) -> Bool {
    convertGeneric(family: .inet, string: string, to: &dst.rawValue)
  }

  static func convert(_ string: UnsafePointer<CChar>, to dst: inout InternetAddress6) -> Bool {
    convertGeneric(family: .inet6, string: string, to: &dst.rawValue)
  }

  static func convertGeneric(family: AddressFamily, string src: UnsafePointer<CChar>, to dst: UnsafeMutableRawPointer) -> Bool {
    let result = inet_pton(numericCast(family.rawValue), src, dst)
    switch result {
    case 1: return true
    case 0: return false
    case -1:
      assert(Errno.addressFamilyNotSupported == .systemCurrent, "-1 is returned and errno is set to EAFNOSUPPORT")
      return false
    default:
      assertionFailure("non-standard result: \(result)!")
      return false
    }
  }
}

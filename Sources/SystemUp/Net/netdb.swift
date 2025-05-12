import SystemLibc
import SystemPackage
import CUtility

public struct AddressInfoList: ~Copyable {
  @usableFromInline
  internal let list: UnsafeMutablePointer<addrinfo>?


public struct Flags: RawRepresentable, Hashable {
  public let rawValue: Int32

  @_alwaysEmitIntoClient
  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  @_alwaysEmitIntoClient
  public static var addrConfig: Self { .init(rawValue: SystemLibc.AI_ADDRCONFIG) }
  @_alwaysEmitIntoClient
  public static var all: Self { .init(rawValue: SystemLibc.AI_ALL) }
  @_alwaysEmitIntoClient
  public static var canonname: Self { .init(rawValue: SystemLibc.AI_CANONNAME) }
  @_alwaysEmitIntoClient
  public static var numericHost: Self { .init(rawValue: SystemLibc.AI_NUMERICHOST) }
  @_alwaysEmitIntoClient
  public static var numericServ: Self { .init(rawValue: SystemLibc.AI_NUMERICSERV) }

    @_alwaysEmitIntoClient
  public static var passive: Self { .init(rawValue: SystemLibc.AI_PASSIVE) }
  @_alwaysEmitIntoClient
  public static var v4Mapped: Self { .init(rawValue: SystemLibc.AI_V4MAPPED) }
  @_alwaysEmitIntoClient
  public static var v4MappedCRF: Self { .init(rawValue: SystemLibc.AI_V4MAPPED_CFG) }
  @_alwaysEmitIntoClient
  public static var `default`: Self { .init(rawValue: SystemLibc.AI_DEFAULT) }
  @_alwaysEmitIntoClient
  public static var unusable: Self { .init(rawValue: SystemLibc.AI_UNUSABLE) }
}

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(hostname: UnsafePointer<CChar>?, servname: UnsafePointer<CChar>?, hints: UnsafePointer<SocketAddressInfo>?) throws(GetAddressInfoError) {
    var v: UnsafeMutablePointer<addrinfo>?
    let code = getaddrinfo(hostname, servname, UnsafeRawPointer(hints)?.assumingMemoryBound(to: addrinfo.self), &v)
    if code != 0 {
      throw GetAddressInfoError.init(rawValue: code)
    }
    self.list = v
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    freeaddrinfo(list)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func iterate<E: Error>(_ body: (_ address: SocketAddressInfo, _ stop: inout Bool) throws(E) -> Void) throws(E) {
    var current = list
    var stop = false
    while let valid = current {
      try body(UnsafeRawPointer(valid).assumingMemoryBound(to: SocketAddressInfo.self)[0], &stop)
      guard !stop else {
        return
      }
      current = valid.pointee.ai_next
    }
  }

}

public struct SocketAddressInfo {

  public init() {
    rawValue = .init()
  }

  @usableFromInline
  internal var rawValue: addrinfo

}

public extension SocketAddressInfo {

  /* AI_PASSIVE, AI_CANONNAME, AI_NUMERICHOST */
//  @_alwaysEmitIntoClient @inlinable @inline(__always)
//  var flags: Flags {
//    get { .init(rawValue: rawValue.ai_flags) }
//    set { rawValue.ai_flags = newValue.rawValue }
//  }

//  PF_UNSPEC
  /// address family
  @_alwaysEmitIntoClient
  var addressFamily: AddressFamily {
    get { .init(rawValue: rawValue.ai_family) }
    set { rawValue.ai_family = numericCast(newValue.rawValue) }
  }

  /* SOCK_xxx */
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var socketType: SocketType {
    get { .init(rawValue: rawValue.ai_socktype) }
    set { rawValue.ai_socktype = newValue.rawValue }
  }

  /* 0 or IPPROTO_xxx for IPv4 and IPv6 */
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var proto: Int32 {
    get { rawValue.ai_protocol }
    set { rawValue.ai_protocol = newValue }
  }

  /* canonical name for hostname */
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func withUnsafeCanonicalName<R>(_ body: (borrowing DynamicCString) throws -> R) rethrows -> R {
    try DynamicCString.withTemporaryBorrowed(cString: rawValue.ai_canonname, body)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var rawLength: UInt32 {
    rawValue.ai_addrlen
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func withAddr<R: ~Copyable, E: Error>(_ body: (borrowing SocketAddress) throws(E) -> R) throws(E) -> R {
    try body(.init(rawValue.ai_addr))
  }
}

public struct ServiceEntry: ~Copyable {
  @usableFromInline
  internal init(_ ptr: UnsafeMutablePointer<servent>) {
    self.ptr = ptr
  }

  @usableFromInline
  internal let ptr: UnsafeMutablePointer<servent>

}
public extension ServiceEntry {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func withNextEntry<R>(_ body: (_ entry: borrowing ServiceEntry) throws -> R) rethrows -> R? {
    guard let ent = getservent() else {
      return nil
    }
    return try body(.init(ent))
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func withNextEntry<R>(name: String, proto: UnsafePointer<CChar>?, _ body: (_ entry: borrowing ServiceEntry) throws -> R) rethrows -> R? {
    guard let ent = getservbyname(name, proto) else {
      return nil
    }
    return try body(.init(ent))
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func withNextEntry<R>(port: Int32, proto: UnsafePointer<CChar>?, _ body: (_ entry: borrowing ServiceEntry) throws -> R) rethrows -> R? {
    guard let ent = getservbyport(port, proto) else {
      return nil
    }
    return try body(.init(ent))
  }
  
  /// Opens a connection to the database, and sets the next entry to the first entry
  /// - Parameter stayOpen: If stayopen is true, then the connection to the database will not be closed between calls to one of the withNextEntry() functions.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func open(stayOpen: Bool) {
    setservent(.init(cBool: stayOpen))
  }
  
  /// Closes the connection to the database.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func close() {
    endservent()
  }
}

public extension ServiceEntry {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var name: String {
    .init(cString: ptr.pointee.s_name)
  }

  /// The official name of the service.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func withNameCString<R>(_ body: (borrowing DynamicCString) throws -> R) rethrows -> R {
    try DynamicCString.withTemporaryBorrowed(cString: ptr.pointee.s_name, body)
  }
  /*
   public var s_aliases: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>! /* alias list */
   */

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var aliases: NullTerminatedArray<UnsafeMutablePointer<CChar>> {
    .init(ptr.pointee.s_aliases)
  }

  /// The port number at which the service resides.  Port number is returned in network byte order.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var port: NetworkByteOrderInteger<UInt16> {
    .init(.init(truncatingIfNeeded: ptr.pointee.s_port))
  }

  /// The name of the protocol to use when contacting the service.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func withUnsafeProtocol<R>(_ body: (borrowing DynamicCString) throws -> R) rethrows -> R {
    try DynamicCString.withTemporaryBorrowed(cString: ptr.pointee.s_proto, body)
  }
}
/*

 /* IPPORT_RESERVED */

 public var _PATH_HEQUIV: String { get }

 public var _PATH_HOSTS: String { get }
 public var _PATH_NETWORKS: String { get }
 public var _PATH_PROTOCOLS: String { get }
 public var _PATH_SERVICES: String { get }

 public var h_errno: Int32

 /*
  * Structures returned by network data base library.  All addresses are
  * supplied in host order, and returned in network order (suitable for
  * use in system calls).
  */
 public struct hostent {

 public init()

 public init(h_name: UnsafeMutablePointer<CChar>!, h_aliases: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, h_addrtype: Int32, h_length: Int32, h_addr_list: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!)

 public var h_name: UnsafeMutablePointer<CChar>! /* official name of host */

 public var h_aliases: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>! /* alias list */

 public var h_addrtype: Int32 /* host address type */

 public var h_length: Int32 /* length of address */

 public var h_addr_list: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>! /* list of addresses from name server */
 }

 /* address, for backward compatibility */
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */

 /*
  * Assumption here is that a network number
  * fits in an unsigned long -- probably a poor one.
  */
 public struct netent {

 public init()

 public init(n_name: UnsafeMutablePointer<CChar>!, n_aliases: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, n_addrtype: Int32, n_net: UInt32)

 public var n_name: UnsafeMutablePointer<CChar>! /* official name of net */

 public var n_aliases: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>! /* alias list */

 public var n_addrtype: Int32 /* net address type */

 public var n_net: UInt32 /* network # */
 }

 public struct protoent {

 public init()

 public init(p_name: UnsafeMutablePointer<CChar>!, p_aliases: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, p_proto: Int32)

 public var p_name: UnsafeMutablePointer<CChar>! /* official protocol name */

 public var p_aliases: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>! /* alias list */

 public var p_proto: Int32 /* protocol # */
 }

 public struct addrinfo {

 public init()

 public init(ai_flags: Int32, ai_family: Int32, ai_socktype: Int32, ai_protocol: Int32, ai_addrlen: socklen_t, ai_canonname: UnsafeMutablePointer<CChar>!, ai_addr: UnsafeMutablePointer<sockaddr>!, ai_next: UnsafeMutablePointer<addrinfo>!)

 public var ai_flags: Int32 /* AI_PASSIVE, AI_CANONNAME, AI_NUMERICHOST */

 public var ai_family: Int32 /* PF_xxx */

 public var ai_socktype: Int32 /* SOCK_xxx */

 public var ai_protocol: Int32 /* 0 or IPPROTO_xxx for IPv4 and IPv6 */

 public var ai_addrlen: socklen_t /* length of ai_addr */

 public var ai_canonname: UnsafeMutablePointer<CChar>! /* canonical name for hostname */

 public var ai_addr: UnsafeMutablePointer<sockaddr>! /* binary address */

 public var ai_next: UnsafeMutablePointer<addrinfo>! /* next structure in linked list */
 }

 public struct rpcent {

 public init()

 public init(r_name: UnsafeMutablePointer<CChar>!, r_aliases: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, r_number: Int32)

 public var r_name: UnsafeMutablePointer<CChar>! /* name of server for this rpc program */

 public var r_aliases: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>! /* alias list */

 public var r_number: Int32 /* rpc program number */
 }
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */

 /*
  * Error return codes from gethostbyname() and gethostbyaddr()
  * (left in h_errno).
  */

 public var NETDB_INTERNAL: Int32 { get } /* see errno */
 public var NETDB_SUCCESS: Int32 { get } /* no problem */
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
 public var HOST_NOT_FOUND: Int32 { get } /* Authoritative Answer Host not found */
 public var TRY_AGAIN: Int32 { get } /* Non-Authoritative Host not found, or SERVERFAIL */
 public var NO_RECOVERY: Int32 { get } /* Non recoverable errors, FORMERR, REFUSED, NOTIMP */
 public var NO_DATA: Int32 { get } /* Valid name, no data record of requested type */

 public var NO_ADDRESS: Int32 { get } /* no address, look for MX record */
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
 /*
  * Error return codes from getaddrinfo()
  */

 public var EAI_ADDRFAMILY: Int32 { get } /* address family for hostname not supported */
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
 public var EAI_AGAIN: Int32 { get } /* temporary failure in name resolution */
 public var EAI_BADFLAGS: Int32 { get } /* invalid value for ai_flags */
 public var EAI_FAIL: Int32 { get } /* non-recoverable failure in name resolution */
 public var EAI_FAMILY: Int32 { get } /* ai_family not supported */
 public var EAI_MEMORY: Int32 { get } /* memory allocation failure */

 public var EAI_NODATA: Int32 { get } /* no address associated with hostname */
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
 public var EAI_NONAME: Int32 { get } /* hostname nor servname provided, or not known */
 public var EAI_SERVICE: Int32 { get } /* servname not supported for ai_socktype */
 public var EAI_SOCKTYPE: Int32 { get } /* ai_socktype not supported */
 public var EAI_SYSTEM: Int32 { get } /* system error returned in errno */

 public var EAI_BADHINTS: Int32 { get } /* invalid value for hints */
 public var EAI_PROTOCOL: Int32 { get } /* resolved protocol is unknown */
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
 public var EAI_OVERFLOW: Int32 { get } /* argument buffer overflow */

 public var EAI_MAX: Int32 { get }
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */

 /*
  * Flag values for getaddrinfo()
  */
 public var AI_PASSIVE: Int32 { get } /* get address to use bind() */
 public var AI_CANONNAME: Int32 { get } /* fill ai_canonname */
 public var AI_NUMERICHOST: Int32 { get } /* prevent host name resolution */
 public var AI_NUMERICSERV: Int32 { get } /* prevent service name resolution */
 /* valid flags for addrinfo (not a standard def, apps should not use it) */

 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
 public var AI_ALL: Int32 { get } /* IPv6 and IPv4-mapped (with AI_V4MAPPED) */

 public var AI_V4MAPPED_CFG: Int32 { get } /* accept IPv4-mapped if kernel supports */
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
 public var AI_ADDRCONFIG: Int32 { get } /* only if any address is assigned */
 public var AI_V4MAPPED: Int32 { get } /* accept IPv4-mapped IPv6 address */
 /* special recommended flags for getipnodebyname */

 public var AI_DEFAULT: Int32 { get }
 /* If the hints pointer is null or ai_flags is zero, getaddrinfo() automatically defaults to the AI_DEFAULT behavior.
  * To override this default behavior, thereby causing unusable addresses to be included in the results, pass any nonzero
  * value for ai_flags, by setting any desired flag values, or by setting AI_UNUSABLE if no other flags are desired. */
 public var AI_UNUSABLE: Int32 { get } /* return addresses even if unusable (i.e. opposite of AI_DEFAULT) */
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */

 /*
  * Constants for getnameinfo()
  */

 public var NI_MAXHOST: Int32 { get }
 public var NI_MAXSERV: Int32 { get }
 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
 /*
  * Flag values for getnameinfo()
  */
 public var NI_NOFQDN: Int32 { get }
 public var NI_NUMERICHOST: Int32 { get }
 public var NI_NAMEREQD: Int32 { get }
 public var NI_NUMERICSERV: Int32 { get }
 public var NI_NUMERICSCOPE: Int32 { get }
 public var NI_DGRAM: Int32 { get }

 public var NI_WITHSCOPEID: Int32 { get }

 /*
  * Scope delimit character
  */

 /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */

 public func endhostent()
 public func endnetent()
 public func endprotoent()
 public func endservent()

 public func gethostbyaddr(_: UnsafeRawPointer!, _: socklen_t, _: Int32) -> UnsafeMutablePointer<hostent>!
 public func gethostbyname(_: UnsafePointer<CChar>!) -> UnsafeMutablePointer<hostent>!
 public func gethostent() -> UnsafeMutablePointer<hostent>!
 public func getnameinfo(_: UnsafePointer<sockaddr>!, _: socklen_t, _: UnsafeMutablePointer<CChar>!, _: socklen_t, _: UnsafeMutablePointer<CChar>!, _: socklen_t, _: Int32) -> Int32
 public func getnetbyaddr(_: UInt32, _: Int32) -> UnsafeMutablePointer<netent>!
 public func getnetbyname(_: UnsafePointer<CChar>!) -> UnsafeMutablePointer<netent>!
 public func getnetent() -> UnsafeMutablePointer<netent>!
 public func getprotobyname(_: UnsafePointer<CChar>!) -> UnsafeMutablePointer<protoent>!
 public func getprotobynumber(_: Int32) -> UnsafeMutablePointer<protoent>!
 public func getprotoent() -> UnsafeMutablePointer<protoent>!
 public func getservbyname(_: UnsafePointer<CChar>!, _: UnsafePointer<CChar>!) -> UnsafeMutablePointer<servent>!
 public func getservbyport(_: Int32, _: UnsafePointer<CChar>!) -> UnsafeMutablePointer<servent>!
 public func getservent() -> UnsafeMutablePointer<servent>!
 public func sethostent(_: Int32)
 /* void    sethostfile(const char *); */
 public func setnetent(_: Int32)
 public func setprotoent(_: Int32)
 public func setservent(_: Int32)

 public func freehostent(_: UnsafeMutablePointer<hostent>!)
 public func gethostbyname2(_: UnsafePointer<CChar>!, _: Int32) -> UnsafeMutablePointer<hostent>!
 public func getipnodebyaddr(_: UnsafeRawPointer!, _: Int, _: Int32, _: UnsafeMutablePointer<Int32>!) -> UnsafeMutablePointer<hostent>!
 public func getipnodebyname(_: UnsafePointer<CChar>!, _: Int32, _: Int32, _: UnsafeMutablePointer<Int32>!) -> UnsafeMutablePointer<hostent>!
 public func getrpcbyname(_ name: UnsafePointer<CChar>!) -> UnsafeMutablePointer<rpcent>!

 public func getrpcbynumber(_ number: Int32) -> UnsafeMutablePointer<rpcent>!

 public func getrpcent() -> UnsafeMutablePointer<rpcent>!
 public func setrpcent(_ stayopen: Int32)
 public func endrpcent()
 public func herror(_: UnsafePointer<CChar>!)
 public func hstrerror(_: Int32) -> UnsafePointer<CChar>!
 public func innetgr(_: UnsafePointer<CChar>!, _: UnsafePointer<CChar>!, _: UnsafePointer<CChar>!, _: UnsafePointer<CChar>!) -> Int32
 public func getnetgrent(_: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, _: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, _: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!) -> Int32
 public func endnetgrent()
 public func setnetgrent(_: UnsafePointer<CChar>!)

 */

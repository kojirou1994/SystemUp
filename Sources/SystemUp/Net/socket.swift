import CUtility
import SystemLibc

public struct SocketDescriptor {
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }
}

public extension SocketDescriptor {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func create(domain: AddressFamily, type: SocketType, protocol: Int32 = 0) throws(Errno) -> Self {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.socket(numericCast(domain.rawValue), type.rawValue, `protocol`)
    }.map(Self.init).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func close() {
    SystemLibc.close(rawValue)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func bind(addr: borrowing SocketAddress, length: UInt32) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.bind(rawValue, addr.rawAddress, length)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func listen(backlog: Int32) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.listen(rawValue, backlog)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func accept() throws(Errno) -> Self {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.accept(rawValue, nil, nil)
    }.map(Self.init).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func accept(addr: inout SocketAddress, length: UnsafeMutablePointer<UInt32>?) throws(Errno) -> Self {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.accept(rawValue, addr.rawAddress, length)
    }.map(Self.init).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func connect(addr: borrowing SocketAddress, length: UInt32) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      SystemLibc.bind(rawValue, addr.rawAddress, length)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func receive(into buf: UnsafeMutableRawBufferPointer, flags: Int32 = 0) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.recv(rawValue, buf.baseAddress, buf.count, flags)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func receive(into buf: UnsafeMutableRawBufferPointer, flags: Int32 = 0, from addr: inout SocketAddress, length: UnsafeMutablePointer<UInt32>?) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.recvfrom(rawValue, buf.baseAddress, buf.count, flags, addr.rawAddress, length)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func send(_ buf: UnsafeRawBufferPointer, flags: Int32 = 0) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.send(rawValue, buf.baseAddress, buf.count, flags)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func send(_ buf: UnsafeRawBufferPointer, flags: Int32 = 0, to addr: borrowing SocketAddress, length: UInt32) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.sendto(rawValue, buf.baseAddress, buf.count, flags, addr.rawAddress, length)
    }.get()
  }
}

// MARK: Helpers
public extension SocketDescriptor {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func bind(addr: inout SocketAddress.IPV4) throws(Errno) {
    try addr.asSocket(bind)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func bind(addr: inout SocketAddress.IPV6) throws(Errno) {
    try addr.asSocket(bind)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func connect(addr: inout SocketAddress.IPV4) throws(Errno) {
    try addr.asSocket(connect)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func connect(addr: inout SocketAddress.IPV6) throws(Errno) {
    try addr.asSocket(connect)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func connect(addrInfo: SocketAddressInfo) throws(Errno) {
    try addrInfo.withAddr { addr throws(Errno) in
      try connect(addr: addr, length: addrInfo.rawLength)
    }
  }
}

public struct SocketType {
  @_alwaysEmitIntoClient
  internal let rawValue: Int32

  @_alwaysEmitIntoClient
  internal init(rawValue: Int32) {
    self.rawValue = rawValue
  }
  #if os(Linux)
  @_alwaysEmitIntoClient
  internal init(rawValue: __socket_type) {
    self.rawValue = numericCast(rawValue.rawValue)
  }
  #endif

  @_alwaysEmitIntoClient
  public static var stream: Self { .init(rawValue: SystemLibc.SOCK_STREAM) }
  @_alwaysEmitIntoClient
  public static var datagram: Self { .init(rawValue: SystemLibc.SOCK_DGRAM) }
  @_alwaysEmitIntoClient
  public static var raw: Self { .init(rawValue: SystemLibc.SOCK_RAW) }
  @_alwaysEmitIntoClient
  public static var reliablyDeliveredMessage: Self { .init(rawValue: SystemLibc.SOCK_RDM) }
  @_alwaysEmitIntoClient
  public static var sequencedPacketStream: Self { .init(rawValue: SystemLibc.SOCK_SEQPACKET) }
}

public struct IPProtocol: MacroRawRepresentable, Hashable {
  public let rawValue: Int32

  @_alwaysEmitIntoClient
  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  @_alwaysEmitIntoClient
  public static var dup: Self { .init(macroValue: SystemLibc.IPPROTO_UDP) }
  @_alwaysEmitIntoClient
  public static var tcp: Self { .init(macroValue: SystemLibc.IPPROTO_TCP) }
}

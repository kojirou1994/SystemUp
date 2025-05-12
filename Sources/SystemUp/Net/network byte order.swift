import SystemLibc

public struct NetworkByteOrderInteger<T: FixedWidthInteger & UnsignedInteger & _ExpressibleByBuiltinIntegerLiteral>: Equatable {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(_ value: T) {
    self.value = value
  }
  
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(hostOrder value: T) {
    self.value = value.bigEndian
  }

  public let value: T

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public var hostOrder: T {
    .init(bigEndian: value)
  }
}

extension NetworkByteOrderInteger: CustomStringConvertible {
  public var description: String {
    "value: \(value), hostOrder: \(hostOrder)"
  }
}

extension NetworkByteOrderInteger: ExpressibleByIntegerLiteral {
  @inlinable @inline(__always)
  public init(integerLiteral value: T) {
    self.init(hostOrder: value)
  }
}

/*

 public struct NetworkByteOrderInteger<T: UnsignedInteger> {
 public init(_ value: T) {
 self.value = value
 }

 public let value: T
 }

 public extension NetworkByteOrderInteger where T == UInt16 {

 init(hostOrder value: T) {
 self.value = swift_hton_u16_to_u16(value)
 }

 var hostOrder: T {
 swift_ntoh_u16_to_u16(value)
 }
 }

 public extension NetworkByteOrderInteger where T == UInt32 {

 init(hostOrder value: T) {
 self.value = swift_hton_u32_to_u32(value)
 }

 var hostOrder: T {
 swift_ntoh_u32_to_u32(value)
 }
 }

 public extension NetworkByteOrderInteger where T == UInt64 {

 init(hostOrder value: T) {
 self.value = swift_hton_u64_to_u64(value)
 }

 var hostOrder: T {
 swift_ntoh_u64_to_u64(value)
 }
 }
 */

import CStringInterop

public struct CStringArray: ~Copyable, @unchecked Sendable {

  @_alwaysEmitIntoClient
  private(set) var cArray: [UnsafeMutablePointer<CChar>?]

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  public init() {
    cArray = [nil]
  }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  deinit {
    cArray.dropLast().forEach { Memory.free($0) }
  }
}

public extension CStringArray {

  @_alwaysEmitIntoClient
  @inlinable
  init(_ strings: some Sequence<some ContiguousUTF8Bytes>) {
    cArray = .init()
    reserveCapacity(strings.underestimatedCount)
    strings.forEach { string in
      cArray.append(try! DynamicCString.copy(bytes: string).take())
    }
    cArray.append(nil)
  }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  borrowing func withUnsafeCArrayPointer<R: ~Copyable, E: Error>(_ body: (UnsafePointer<UnsafeMutablePointer<CChar>?>) throws(E) -> R) throws(E) -> R {
    try body(cArray)
  }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  mutating func append(_ string: consuming DynamicCString) {
    cArray[cArray.count-1] = string.take()
    cArray.append(nil)
  }

  @_alwaysEmitIntoClient
  @inlinable
  mutating func append(contentsOf strings: some Sequence<some ContiguousUTF8Bytes>) {
    cArray.removeLast()
    reserveCapacity(strings.underestimatedCount)
    strings.forEach { string in
      cArray.append(try! DynamicCString.copy(bytes: string).take())
    }
    cArray.append(nil)
  }

  @_alwaysEmitIntoClient
  @inlinable @inline(__always)
  mutating func reserveCapacity(_ n: Int) {
    cArray.reserveCapacity(n)
  }

}

import SwiftFix

@_alwaysEmitIntoClient
public func withTempUnsafeCStringArray<R: ~Copyable, E: Error>(_ args: some Collection<some ContiguousUTF8Bytes>, _ body: (_ argv: UnsafePointer<UnsafeMutablePointer<CChar>?>) throws(E) -> R) throws(E) -> R {

  if _slowPath(args.isEmpty) {
    var finish: UnsafeMutablePointer<CChar>? = nil
    return try body(&finish)
  }

  let bufferSize = args.reduce(into: args.count) { $0 += $1.withContiguousUTF8Bytes { $0.count } }

  return try withUnsafeTemporaryAllocationTyped(of: UInt8.self, capacity: bufferSize) { argsBuffer throws(E) in

    try withUnsafeTemporaryAllocationTyped(of: UnsafeMutablePointer<CChar>?.self, capacity: args.count+1) { cStrings throws(E) in
      var current = argsBuffer.baseAddress.unsafelyUnwrapped

      for (offset, arg) in args.enumerated() {
        cStrings[offset] = UnsafeMutableRawPointer(current).assumingMemoryBound(to: CChar.self)
        arg.withContiguousUTF8Bytes { utf8Bytes in
          if let baseAddress = utf8Bytes.baseAddress {
            current.initialize(from: baseAddress.assumingMemoryBound(to: UInt8.self), count: utf8Bytes.count)
            current += utf8Bytes.count
          }
        }
        current.pointee = 0
        current += 1
      }

      precondition(current == argsBuffer.baseAddress.unsafelyUnwrapped.advanced(by: argsBuffer.count), "argsBuffer not fullly initialized")

      cStrings[cStrings.count-1] = nil

      return try body(cStrings.baseAddress.unsafelyUnwrapped)
    }
  }

}

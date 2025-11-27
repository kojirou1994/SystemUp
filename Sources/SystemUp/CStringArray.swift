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

@_alwaysEmitIntoClient
public func withTempUnsafeCStringArray<R: ~Copyable, E: Error>(_ args: some Collection<some ContiguousUTF8Bytes>, _ body: (_ argv: UnsafePointer<UnsafeMutablePointer<CChar>?>) throws(E) -> R) throws(E) -> R {

  var argsOffsets = [0]
  argsOffsets.reserveCapacity(args.count)
  var currentOffset = 0
  for arg in args {
    currentOffset += arg.withContiguousUTF8Bytes(\.count) + 1
    argsOffsets.append(currentOffset)
  }

  let argsBufferSize = currentOffset
  var argsBuffer = [UInt8]()
  argsBuffer.reserveCapacity(argsBufferSize)
  for arg in args {
    arg.withContiguousUTF8Bytes { argsBuffer.append(contentsOf: $0) }
    argsBuffer.append(0)
  }

  var result: R!

  try argsBuffer.withUnsafeMutableBufferPointer { argsBuffer throws(E) in
    let ptr = UnsafeMutableRawPointer(argsBuffer.baseAddress!)
      .assumingMemoryBound(to: CChar.self)
    var cStrings: [UnsafeMutablePointer<CChar>?] = argsOffsets.map { ptr + $0 }
    cStrings[cStrings.count - 1] = nil
    result = try body(cStrings)
  }

  return result
}

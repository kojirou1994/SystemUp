import SyscallValue

public extension SyscallUtilities {
  @_alwaysEmitIntoClient
  @inlinable
  static func preallocateSyscall<S: FixedWidthInteger, R: SyscallValue>(_ body: (_ mode: PreAllocateCallMode) throws(Errno) -> S) throws(Errno) -> R {
    let bufsize = try body(.getSize)

    let capacity = Int(bufsize)
    return try R(bytesCapacity: capacity) { buffer throws(Errno) in
      let realsize = try body(.getValue(buffer))
      return Int(realsize)
    }
  }

  /// fill reusable buffer data by syscall
  /// - Parameters:
  ///   - buffer: reused buffer, maybe resized
  ///   - body: syscall body
  /// - Returns: buffer slice bounded to Item
  @_alwaysEmitIntoClient
  @inlinable
  static func preallocateSyscall<S: FixedWidthInteger, Item>(buffer: inout UnsafeMutableRawBufferPointer, _ body: (_ mode: PreAllocateCallMode) throws(Errno) -> S) throws(Errno) -> UnsafeMutableBufferPointer<Item> {
    let byteCount = try body(.getSize)
    if buffer.count < byteCount {
      try Memory.resize(&buffer, byteCount: Int(byteCount))
    }
    let validBytes = try body(.getValue(buffer))

    assert(Int(validBytes) % MemoryLayout<Item>.stride == 0, "Item size wrong?")

    return buffer.prefix(Int(validBytes)).assumingMemoryBound(to: Item.self)
  }
}

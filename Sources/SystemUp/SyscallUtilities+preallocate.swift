import SystemPackage
import SyscallValue

public extension SyscallUtilities {
  @_alwaysEmitIntoClient
  @inlinable
  static func preallocateSyscall<S: FixedWidthInteger, R: SyscallValue>(_ body: (_ mode: PreAllocateCallMode) -> Result<S, Errno>) -> Result<R, Errno> {
    switch body(.getSize) {
    case .failure(let err): return .failure(err)
    case .success(let bufsize):
      do {
        let capacity = Int(bufsize)
        let v = try R(bytesCapacity: capacity) { buffer in
          let realsize = try body(.getValue(buffer)).get()
          return Int(realsize)
        }
        return .success(v)
      } catch let err as Errno {
        return .failure(err)
      } catch { fatalError() }
    }
  }

  /// fill reusable buffer data by syscall
  /// - Parameters:
  ///   - buffer: reused buffer, maybe resized
  ///   - body: syscall body
  /// - Returns: buffer slice bounded to Item
  @_alwaysEmitIntoClient
  @inlinable
  static func preallocateSyscall<S: FixedWidthInteger, Item>(buffer: inout UnsafeMutableRawBufferPointer, _ body: (_ mode: PreAllocateCallMode) -> Result<S, Errno>) -> Result<UnsafeMutableBufferPointer<Item>, Errno> {
    switch body(.getSize) {
    case .failure(let err): return .failure(err)
    case .success(let byteCount):
      do {
        if buffer.count < byteCount {
          try Memory.resize(&buffer, byteCount: Int(byteCount))
        }
        let validBytes = try body(.getValue(buffer)).get()

        assert(Int(validBytes) % MemoryLayout<Item>.stride == 0, "Item size wrong?")

        return .success(buffer.prefix(Int(validBytes)).assumingMemoryBound(to: Item.self))
      } catch let err as Errno {
        return .failure(err)
      } catch { fatalError() }
    }
  }
}

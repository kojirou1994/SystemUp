import Foundation
import SystemPackage

extension Data {

  public init(contentsOfFileDescriptor fd: FileDescriptor) throws {
    let size = try FileSyscalls.fileStatus(fd).get().size
    let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

    let count = try fd.read(into: buffer)
    self.init(bytesNoCopy: buffer.baseAddress!, count: count, deallocator: .free)
  }
}

extension Array where Element == UInt8 {
  public init(contentsOfFileDescriptor fd: FileDescriptor) throws {
    let size = try FileSyscalls.fileStatus(fd).get().size

    try self.init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
      initializedCount = try fd.read(into: .init(buffer))
    }
  }
}

extension ContiguousArray where Element == UInt8 {
  public init(contentsOfFileDescriptor fd: FileDescriptor) throws {
    let size = try FileSyscalls.fileStatus(fd).get().size

    try self.init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
      initializedCount = try fd.read(into: .init(buffer))
    }
  }
}

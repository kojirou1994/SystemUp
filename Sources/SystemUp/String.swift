import SystemPackage

extension String {
  //  @inlinable
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public init(utf8ContentsOfFileDescriptor fd: FileDescriptor) throws {
    let size = try FileSyscalls.fileStatus(fd).get().size

    try self.init(unsafeUninitializedCapacity: Int(size)) { buffer in
      try fd.read(into: UnsafeMutableRawBufferPointer(buffer))
    }
  }

  public init<T: Unicode.Encoding>(decodingContentsOfFileDescriptor fd: FileDescriptor, as sourceEncoding: T.Type) throws {

    let size = try FileSyscalls.fileStatus(fd).get().size

    let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<UInt8>.alignment)
    defer {
      buffer.deallocate()
    }

    let count = try fd.read(into: buffer)

    self.init(decoding: UnsafeRawBufferPointer(start: buffer.baseAddress, count: count).bindMemory(to: T.CodeUnit.self), as: T.self)
  }
}


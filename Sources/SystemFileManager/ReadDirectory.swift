import SystemUp
import SystemPackage

@available(macOS 10.15.0, iOS 13.0.0, *)
public actor ReadDirectory {

  public init(_ stream: Directory) {
    self.stream = stream
  }

  public let stream: Directory

  public struct Entry {
    public let entryFileNumber: CInterop.UpInodeNumber
    public let seekOffset: CInterop.UpSeekOffset
    public let recordLength: UInt16
    public let fileType: Directory.DirectoryType
    public let name: String
  }

  public func read() throws -> Entry? {
    try stream.withNextEntry { entry in
      Entry(entryFileNumber: entry.entryFileNumber, seekOffset: entry.seekOffset, recordLength: entry.recordLength, fileType: entry.fileType, name: entry.name)
    }?.get()
  }

}

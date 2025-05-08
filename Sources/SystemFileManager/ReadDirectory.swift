import SystemUp
import SystemPackage

@available(macOS 10.15.0, iOS 13.0.0, *)
public actor DirectoryReader {

  public init(_ stream: consuming Directory) {
    self.stream = stream
  }

  internal let stream: Directory

  public struct Entry {
    public let entryFileNumber: CInterop.UpInodeNumber
    public let seekOffset: CInterop.UpSeekOffset
    public let recordLength: UInt16
    public let fileType: Directory.DirectoryType
    public let name: String
  }

  public func read() throws -> Entry? {
    if let entry = try stream.next() {
      .init(entryFileNumber: entry.entryFileNumber, seekOffset: entry.seekOffset, recordLength: entry.recordLength, fileType: entry.fileType, name: entry.name)
    } else {
      nil
    }
  }

}

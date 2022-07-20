import SystemPackage
import SystemUp

public struct DirectoryEntrySequence: Sequence, IteratorProtocol {
  public init(directory: Directory) {
    self.directory = directory
  }

  public let directory: Directory

  public func next() -> Directory.Entry? {
    try? directory.read().get()?.pointee
  }

}

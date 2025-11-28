import Foundation

extension SystemFileManager {
  @available(iOS 11.0, *)
  public static func delete(_ path: FilePath, trashIfAvailable: Bool, or removeMethod: (FilePath) throws -> Void = { try remove($0) }) throws {
    #if os(macOS) || os(iOS)
    if trashIfAvailable {
      try FileManager.default.trashItem(at: URL(fileURLWithPath: path.string), resultingItemURL: nil)
    } else {
      try removeMethod(path)
    }
    #else
    try removeMethod(path)
    #endif
  }
}

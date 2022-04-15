import Foundation
import SystemPackage

extension SystemFileManager {
  @available(iOS 11.0, *)
  public static func delete(_ path: FilePath, trashIfAvailable: Bool) throws {
    #if os(macOS) || os(iOS)
    if trashIfAvailable {
      try FileManager.default.trashItem(at: URL(fileURLWithPath: path.string), resultingItemURL: nil)
    } else {
      try remove(path).get()
    }
    #else
    try remove(path).get()
    #endif
  }
}

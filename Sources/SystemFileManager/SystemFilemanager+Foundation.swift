#if !$Embedded
import Foundation
import CUtility

extension SystemFileManager {
  @available(iOS 11.0, *)
  public static func delete(_ path: borrowing some CString, trashIfAvailable: Bool, or removeMethod: (UnsafePointer<CChar>) throws -> Void = { try SystemFileManager.remove($0) }) throws {
    try path.withUnsafeCString { path in
      #if os(macOS) || os(iOS)
      if trashIfAvailable {
        try FileManager.default.trashItem(at: URL(fileURLWithFileSystemRepresentation: path, isDirectory: false, relativeTo: nil), resultingItemURL: nil)
      } else {
        try removeMethod(path)
      }
      #else
      try removeMethod(path)
      #endif
    }
  }
}
#endif

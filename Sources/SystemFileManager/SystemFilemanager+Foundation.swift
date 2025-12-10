#if !$Embedded
import Foundation
import CUtility
import SystemUp

public extension SystemFileManager {
  @available(iOS 11.0, *)
  static func delete(_ path: borrowing some CString, trashIfAvailable: Bool, or removeMethod: (UnsafePointer<CChar>) throws -> Void = { try SystemFileManager.remove($0) }) throws {
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

  static func contents(ofFile path: borrowing some CString, mode: FullContentLoadMode = .length) throws -> Data {
    try SystemCall.open(path, .readOnly)
      .closeAfter { fd in
        try contents(ofFileDescriptor: fd, mode: mode)
      }
  }

  static func contents(ofFileDescriptor fd: FileDescriptor, mode: FullContentLoadMode = .length) throws -> Data {
    switch mode {
    case .length:
      let size = try length(fd: fd)
      guard size > 0 else {
        return .init()
      }
      var data = Data(count: size)
      let realsize = try data.withUnsafeMutableBytes { buffer throws(Errno) in
        try fd.read(into: buffer)
      }
      assert(realsize == size, "size changed?")
      data.removeLast(realsize - size)
      return data
    case .stream(let bufferSize):
      return try streamRead(fd: fd, bufferSize: bufferSize)
    }
  }
}
#endif

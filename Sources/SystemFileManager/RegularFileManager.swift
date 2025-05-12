import SystemUp
import SystemPackage

public enum RegularFileManager {
  /// src must be regular file, dst must not exist, dst is deleted if failure
  public static func slowCopyFile(src: FilePath, dst: FilePath, bufferSize: Int = 4096) throws {
    let inFD = try FileDescriptor.open(src, .readOnly)
    defer {
      try? inFD.close()
    }

    assert(try! SystemFileManager.fileStatus(inFD, \.fileType) == .regular)

    let outFD = try FileDescriptor.open(dst, .writeOnly, options: [.create, .exclusiveCreate], permissions: .fileDefault)
    defer {
      try? outFD.close()
    }

    do {
      try withUnsafeTemporaryAllocation(byteCount: bufferSize, alignment: MemoryLayout<UInt>.alignment) { buffer in
        while case let length = try inFD.read(into: buffer), length > 0 {
          try outFD.writeAll(UnsafeRawBufferPointer(rebasing: buffer.prefix(length)))
        }
      }
    } catch {
      // delete failed dst
      try? SystemCall.unlink(dst)
    }
  }

  /// returns true if linked, false if copied
  public static func linkOrCopyFile(src: FilePath, dst: FilePath) throws -> Bool {
    assert(try! SystemFileManager.fileStatus(src, \.fileType) == .regular)
    do {
      try SystemCall.createHardLink(dst, toDestination: src)
      return true
    } catch {
      switch error {
      case .improperLink:
        try slowCopyFile(src: src, dst: dst)
        return false
      default: throw error
      }
    }
  }

  /// returns true if renamed, false if copied
  public static func renameOrCopyFileAndDeleteSRC(src: FilePath, dst: FilePath, ignoreDeleleSRCError: Bool = true) throws -> Bool {
    assert(try! SystemFileManager.fileStatus(src, \.fileType) == .regular)
    do {
      try SystemCall.rename(src, toDestination: dst, flags: .exclusive)
      return true
    } catch {
      switch error {
      case .improperLink:
        try slowCopyFile(src: src, dst: dst)
        do {
          try SystemCall.unlink(src)
        } catch {
          if !ignoreDeleleSRCError {
            throw error
          }
        }
        return false
      default: throw error
      }
    }
  }
}

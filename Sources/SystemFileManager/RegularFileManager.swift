import SystemUp
import CUtility

public enum RegularFileManager {
  /// src must be regular file, dst must not exist, dst is deleted if failure
  public static func slowCopyFile(src: borrowing some CString, dst: borrowing some CString, bufferSize: Int? = nil) throws(Errno) {
    let inFD = try SystemCall.open(src, .readOnly)
    defer {
      try? SystemCall.close(inFD)
    }

    var instat: FileStatus = Memory.undefined()
    try SystemCall.fileStatus(inFD, into: &instat)
    assert(instat.fileType == .regular)

    let inSize = instat.size

    let outFD = try SystemCall.open(dst, .writeOnly, options: [.create, .exclusiveCreate], permissions: .fileDefault)
    defer {
      try? SystemCall.close(outFD)
    }

    // preallocate and ignore error
    do {
      #if APPLE
      var opt = FileControl.PreAllocateOptions()
      opt.flags = []
      opt.positionMode = .endOfFile
      opt.offset = 0
      opt.length = inSize
      try? FileControl.preAllocate(outFD, options: &opt)
      #elseif os(Linux)
      try? SystemCall.fallocate(outFD, offset: 0, length: inSize)
      #endif
    }

    do {
      let bsize = bufferSize ?? BlockSizes(src: inFD, srcStat: instat, dst: outFD).cb_src_bsize
      try withUnsafeTemporaryAllocationTyped(byteCount: bsize, alignment: MemoryLayout<UInt>.alignment) { buffer throws(Errno) in
        while case let length = try inFD.read(into: buffer), length > 0 {
          try outFD.writeAll(UnsafeRawBufferPointer(rebasing: buffer.prefix(length)))
        }
      }
    } catch {
      // delete failed dst
      try? SystemCall.unlink(dst)
      throw error
    }

    assert(try! SystemFileManager.fileStatus(inFD, \.size) == SystemFileManager.fileStatus(outFD, \.size))
  }

  /// returns true if linked, false if copied
  public static func linkOrCopyFile(src: borrowing some CString, dst: borrowing some CString) throws(Errno) -> Bool {
    assert(try! SystemFileManager.fileStatus(src, \.fileType) == .regular)
    do {
      try SystemCall.createHardLink(dst, toDestination: src)
      return true
    } catch {
      try slowCopyFile(src: src, dst: dst)
      return false
    }
  }

  /// returns true if renamed, false if copied
  public static func renameOrCopyFileAndDeleteSRC(src: borrowing some CString, dst: borrowing some CString, ignoreDeleleSRCError: Bool = true) throws(Errno) -> Bool {
    assert(try! SystemFileManager.fileStatus(src, \.fileType) == .regular)
    do {
      try SystemCall.rename(src, toDestination: dst, flags: .exclusive)
      return true
    } catch {
      try slowCopyFile(src: src, dst: dst)
      do {
        try SystemCall.unlink(src)
      } catch {
        if !ignoreDeleleSRCError {
          throw error
        }
      }
      return false
    }
  }
}

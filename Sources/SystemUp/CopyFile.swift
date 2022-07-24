#if canImport(Darwin)
import Darwin
import SystemPackage

public struct CopyFileReturn: RawRepresentable {
  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }

  public let rawValue: CInt

  /// The copy will continue as expected.
  @_alwaysEmitIntoClient
  public static var `continue`: Self { .init(macroValue: COPYFILE_CONTINUE) }
  /// This object will be skipped, and the next object will be processed.  (Note that, when entering a directory, returning COPYFILE_SKIP from the call-back function will prevent the contents of the directory from being copied.)
  @_alwaysEmitIntoClient
  public static var skip: Self { .init(macroValue: COPYFILE_SKIP) }
  /// The entire copy is aborted at this stage.  Any filesystem objects created up to this point will remain.  copyfile() will return -1, but errno will be unmodified.
  @_alwaysEmitIntoClient
  public static var quit: Self { .init(macroValue: COPYFILE_QUIT) }
}

public struct CopyFileStage: RawRepresentable, Equatable {
  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }

  public let rawValue: CInt

  /// Before copying has begun.  The third parameter will be a newly-created copyfile_state_t object with the call-back function and context pre-loaded.
  @_alwaysEmitIntoClient
  public static var start: Self { .init(macroValue: COPYFILE_START) }

  /// After copying has successfully finished.
  @_alwaysEmitIntoClient
  public static var finish: Self { .init(macroValue: COPYFILE_FINISH) }

  /// Indicates an error has happened at some stage.  If the first argument to the call-back function is COPYFILE_RECURSE_ERROR, then an error occurred while processing the source hierarchy; otherwise, it will indicate what type of object was being copied, and errno will be set to indicate the error.
  @_alwaysEmitIntoClient
  public static var error: Self { .init(macroValue: COPYFILE_ERR) }

  @_alwaysEmitIntoClient
  public static var progress: Self { .init(macroValue: COPYFILE_PROGRESS) }
}

extension CopyFileStage: CustomStringConvertible {
  public var description: String {
    switch self {
    case .start: return "start"
    case .finish: return "finish"
    case .error: return "error"
    case .progress: return "progress"
    default: return "unkonwn stage(rawValue: \(rawValue))"
    }
  }
}


public final class CopyFileState {

  public typealias Callback = (CopyFileWhat, CopyFileStage, CopyFileState) -> CopyFileReturn

  fileprivate let state: copyfile_state_t

  public var callback: Callback?

  public init() throws {
    guard let state = copyfile_state_alloc() else {
      throw Errno.noMemory
    }
    self.state = state
  }

  public func set(callbackEnabled: Bool) throws -> Self {
    if callbackEnabled {
      _ = try _set(flag: COPYFILE_STATE_STATUS_CTX, thing: unsafeBitCast(self, to: UnsafeRawPointer.self))
      _ = try _set(flag: COPYFILE_STATE_STATUS_CB, thing: unsafeBitCast(copyfile_callback as copyfile_callback_t, to: UnsafeRawPointer.self))
    } else {
      _ = try _set(flag: COPYFILE_STATE_STATUS_CTX, thing: nil)
      _ = try _set(flag: COPYFILE_STATE_STATUS_CB, thing: nil)
    }
    return self
  }

  deinit {
    copyfile_state_free(state)
  }

  /*

   COPYFILE_STATE_XATTRNAME     Get the name of the extended attribute during a callback for COPYFILE_COPY_XATTR (see below for details).  This field cannot be set, and may be NULL.

   COPYFILE_STATE_WAS_CLONED    True if a COPYFILE_CLONE or COPYFILE_CLONE_FORCE operation successfully cloned the requested objects.  The dst parameter is a pointer to bool (type bool * ).

   */

  private func set<T>(flag: Int32, value: T) throws -> Self {
    try withUnsafeBytes(of: value) { buffer in
      try _set(flag: flag, thing: buffer.baseAddress)
    }
  }

  private func _set(flag: Int32, thing: UnsafeRawPointer?) throws -> Self {
    try nothingOrErrno(retryOnInterrupt: false) {
      copyfile_state_set(state, UInt32(flag), thing)
    }.get()
    return self
  }

  /// Get the number of data bytes copied so far.  (Only valid for copyfile_state_get(); see below for more details about callbacks.)  If a COPYFILE_CLONE or COPYFILE_CLONE_FORCE operation successfully cloned the requested objects, then this value will be 0.
  public var copiedBytes: off_t {
    try! get(flag: COPYFILE_STATE_COPIED)
  }

  /// True if a COPYFILE_CLONE or COPYFILE_CLONE_FORCE operation successfully cloned the requested objects.
  public var cloned: Bool {
    var result: Bool = false
    try! _get(flag: COPYFILE_STATE_WAS_CLONED, thing: &result)
    return result
  }

  public var srcFD: FileDescriptor {
    .init(rawValue: try! get(flag: COPYFILE_STATE_SRC_FD))
  }

  public var dstFD: FileDescriptor {
    .init(rawValue: try! get(flag: COPYFILE_STATE_DST_FD))
  }

  public var src: FilePath? {
    try! getPath(flag: COPYFILE_STATE_SRC_FILENAME)
  }

  public var dst: FilePath? {
    try! getPath(flag: COPYFILE_STATE_DST_FILENAME)
  }

  private func get<T: FixedWidthInteger>(flag: Int32) throws -> T {
    var result: T = 0
    try _get(flag: flag, thing: &result)
    return result
  }

  private func getPath(flag: Int32) throws -> FilePath? {
    var ptr: UnsafeMutablePointer<CChar>?
    try _get(flag: flag, thing: &ptr)
    return ptr.map { FilePath(platformString: $0) }
  }

  private func _get(flag: Int32, thing: UnsafeMutableRawPointer) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      copyfile_state_get(state, UInt32(flag), thing)
    }.get()
  }

  public func set(srcFD: FileDescriptor?) throws -> Self {
    try set(flag: COPYFILE_STATE_SRC_FD, value: srcFD?.rawValue ?? -2)
  }

  public func set(src: FilePath) throws -> Self {
    try src.withPlatformString { path in
      try _set(flag: COPYFILE_STATE_SRC_FILENAME, thing: path)
    }
  }

  public func set(dstFD: FileDescriptor?) throws -> Self {
    try set(flag: COPYFILE_STATE_DST_FD, value: dstFD?.rawValue ?? -2)
  }

  public func set(dst: FilePath) throws -> Self {
    try dst.withPlatformString { path in
      try _set(flag: COPYFILE_STATE_DST_FILENAME, thing: path)
    }
  }

}

public struct CopyFileWhat: RawRepresentable, Equatable {
  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }

  public let rawValue: CInt

  /// There was an error in processing an element of the source hierarchy; this happens when fts(3) returns an error or unknown file type.  (Currently, the second argu-ment to the call-back function will always be COPYFILE_ERR in this case.)
  @_alwaysEmitIntoClient
  public static var error: Self { .init(macroValue: COPYFILE_RECURSE_ERROR) }

  /// The object being copied is a file (or, rather, something other than a directory).
  @_alwaysEmitIntoClient
  public static var file: Self { .init(macroValue: COPYFILE_RECURSE_FILE) }

  /// The object being copied is a directory, and is being entered.  (That is, none of the filesystem objects contained within the directory have been copied yet.)
  @_alwaysEmitIntoClient
  public static var dir: Self { .init(macroValue: COPYFILE_RECURSE_DIR) }
  /// The object being copied is a directory, and all of the objects contained have been copied.  At this stage, the destination directory being copied will have any extra permissions that were added to allow the copying will be removed.
  @_alwaysEmitIntoClient
  public static var dirCleanup: Self { .init(macroValue: COPYFILE_RECURSE_DIR_CLEANUP) }

  @_alwaysEmitIntoClient
  public static var copyData: Self { .init(macroValue: COPYFILE_COPY_DATA) }

  @_alwaysEmitIntoClient
  public static var copyXattr: Self { .init(macroValue: COPYFILE_COPY_XATTR) }
}

extension CopyFileWhat: CustomStringConvertible {
  public var description: String {
    switch self {
    case .file: return "file"
    case .dir: return "dir"
    case .error: return "error"
    case .dirCleanup: return "dirCleanup"
    case .copyData: return "copyData"
    case .copyXattr: return "copyXattr"
    default: return "CopyFileWhat(unknownRawValue: \(rawValue))"
    }
  }
}

private func copyfile_callback(what: Int32, stage: Int32, state: copyfile_state_t?, src: UnsafePointer<CChar>?, dst: UnsafePointer<CChar>?, ctx: UnsafeMutableRawPointer?) -> Int32 {
  let context = unsafeBitCast(ctx, to: CopyFileState.self)
  return context.callback?(.init(rawValue: what), .init(rawValue: stage), context).rawValue ?? COPYFILE_CONTINUE
}

extension FileSyscalls {

  public static func copyFile(from src: FilePath, to dst: FilePath, state: CopyFileState? = nil, flags: CopyFlags = []) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      src.withPlatformString { src in
        dst.withPlatformString { dst in
          copyfile(src, dst, state?.state, flags.rawValue)
        }
      }
    }
  }

  public static func copyFile(from src: FileDescriptor, to dst: FileDescriptor, state: CopyFileState? = nil, flags: CopyFlags = []) -> Result<Void, Errno> {
    assert(
      CopyFlags([.recursive, .exclusive, .nofollowSrc,
                 .nofollowDst, .nofollow, .move, .unlink,
                 .clone, .cloneForce])
      .intersection(flags).isEmpty, "has flags for path based copyfile")
    return nothingOrErrno(retryOnInterrupt: false) {
      fcopyfile(src.rawValue, dst.rawValue, state?.state, flags.rawValue)
    }
  }

}

public struct CopyFlags: OptionSet {
  public init(rawValue: copyfile_flags_t) {
    self.rawValue = rawValue
  }

  public let rawValue: copyfile_flags_t

  // MARK: copied contents

  /// Copy the source file's access control lists.
  @_alwaysEmitIntoClient
  public static var acl: Self { .init(macroValue: COPYFILE_ACL) }

  /// Copy the source file's POSIX information (mode, modification time, etc.).
  @_alwaysEmitIntoClient
  public static var stat: Self { .init(macroValue: COPYFILE_STAT) }

  /// Copy the source file's extended attributes.
  @_alwaysEmitIntoClient
  public static var xattr: Self { .init(macroValue: COPYFILE_XATTR) }

  /// Copy the source file's data.
  @_alwaysEmitIntoClient
  public static var data: Self { .init(macroValue: COPYFILE_DATA) }

  /// Copy the source file's POSIX and ACL information; equivalent to[.stat, .acl].
  @_alwaysEmitIntoClient
  public static var security: Self { .init(macroValue: COPYFILE_SECURITY) }

  /// Copy the metadata; equivalent to [.security, xattr].
  @_alwaysEmitIntoClient
  public static var metadata: Self { .init(macroValue: COPYFILE_METADATA) }

  /// Copy the entire file; equivalent to [.metadata, .data].
  @_alwaysEmitIntoClient
  public static var all: Self { .init(macroValue: COPYFILE_ALL) }

  // MARK: behavior flags

  /// Causes copyfile() to recursively copy a hierarchy.
  @_alwaysEmitIntoClient
  public static var recursive: Self { .init(macroValue: COPYFILE_RECURSIVE) }

  /// Return a bitmask (corresponding to the flags argument) indicating which contents would be copied; no data are actually copied.  (E.g., if flags was set to COPYFILE_CHECK|COPYFILE_METADATA, and the from file had extended attributes but no ACLs, the return value would be COPYFILE_XATTR .)
  @_alwaysEmitIntoClient
  public static var check: Self { .init(macroValue: COPYFILE_CHECK) }

  /// Fail if the to file already exists.
  @_alwaysEmitIntoClient
  public static var exclusive: Self { .init(macroValue: COPYFILE_EXCL) }

  /// Do not follow the from file, if it is a symbolic link.
  @_alwaysEmitIntoClient
  public static var nofollowSrc: Self { .init(macroValue: COPYFILE_NOFOLLOW_SRC) }

  /// Do not follow the to file, if it is a symbolic link.
  @_alwaysEmitIntoClient
  public static var nofollowDst: Self { .init(macroValue: COPYFILE_NOFOLLOW_DST) }

  /// Unlink (using remove(3)) the from file. No error is returned if remove(3) fails.  Note that remove(3) removes a symbolic link itself, not the tar-get of the link.
  @_alwaysEmitIntoClient
  public static var move: Self { .init(macroValue: COPYFILE_MOVE) }

  /// Unlink the to file before starting.
  @_alwaysEmitIntoClient
  public static var unlink: Self { .init(macroValue: COPYFILE_UNLINK) }

  /// This is a convenience macro, equivalent to [.nofollowSrc, .nofollowDst].
  @_alwaysEmitIntoClient
  public static var nofollow: Self { .init(macroValue: COPYFILE_NOFOLLOW) }

  /// Serialize the from file.  The to file is an AppleDouble-format file.
  @_alwaysEmitIntoClient
  public static var pack: Self { .init(macroValue: COPYFILE_PACK) }

  /// Unserialize the from file.  The from file is an AppleDouble-format file; the to file will have the extended attributes, ACLs, resource fork, and FinderInfo data from the to file, regardless of the flags argument passed in.
  @_alwaysEmitIntoClient
  public static var unpack: Self { .init(macroValue: COPYFILE_UNPACK) }

  /// Try to clone the file instead.  This is a best try flag i.e. if cloning fails, fallback to copying the
  /// file.  This flag is equivalent to (COPYFILE_EXCL | COPYFILE_ACL | COPYFILE_STAT | COPYFILE_XATTR |
  /// COPYFILE_DATA | COPYFILE_NOFOLLOW_SRC).  Note that if cloning is successful, progress callbacks will
  /// not be invoked.  Note also that there is no support for cloning directories: if a directory is provided
  /// as the source and COPYFILE_CLONE_FORCE is not passed, this will instead copy the directory.  Since this
  /// flag implies COPYFILE_NOFOLLOW_SRC, symbolic links themselves will be cloned instead of their targets.
  /// Recursive copying however is supported, see below for more information.
  @_alwaysEmitIntoClient
  public static var clone: Self { .init(macroValue: COPYFILE_CLONE) }

  /// Clone the file instead.  This is a force flag i.e. if cloning fails, an error is returned.This flag
  /// is equivalent to (COPYFILE_EXCL | COPYFILE_ACL | COPYFILE_STAT | COPYFILE_XATTR | COPYFILE_DATA | COPY-
  /// FILE_NOFOLLOW_SRC).  Note that if cloning is successful, progress callbacks will not be invoked.  Note
  /// also that there is no support for cloning directories: if a directory is provided as the source, an
  /// error will be returned.  Since this flag implies COPYFILE_NOFOLLOW_SRC, symbolic links themselves will
  /// be cloned instead of their targets.
  @_alwaysEmitIntoClient
  public static var cloneForce: Self { .init(macroValue: COPYFILE_CLONE_FORCE) }

  /// If the src file has quarantine information, add the QTN_FLAG_DO_NOT_TRANSLOCATE flag to the quarantine
  /// information of the dst file.  This allows a bundle to run in place instead of being translocated.
  @_alwaysEmitIntoClient
  public static var runInPlace: Self { .init(macroValue: COPYFILE_RUN_IN_PLACE) }

  /// Copy a file sparsely.  This requires that the source and destination file systems support sparse files
  /// with hole sizes at least as large as their block sizes.  This also requires that the source file is
  /// sparse, and for fcopyfile() the source file descriptor's offset be a multiple of the minimum hole size.
  /// If COPYFILE_DATA is also specified, this will fall back to a full copy if sparse copying cannot be performed for any reason; otherwise, an error is returned.
  @_alwaysEmitIntoClient
  public static var dataSparse: Self { .init(macroValue: COPYFILE_DATA_SPARSE) }

  /// Preserve the UF_TRACKED flag at to when copying metadata, regardless of whether from has it set.  This
  /// flag is used in conjunction with COPYFILE_STAT, or COPYFILE_CLONE (for its fallback case).
  @_alwaysEmitIntoClient
  public static var preserveDstTracked: Self { .init(macroValue: COPYFILE_PRESERVE_DST_TRACKED) }

  @_alwaysEmitIntoClient
  public static var verbose: Self { .init(macroValue: COPYFILE_VERBOSE) }
}

#endif // Darwin platform

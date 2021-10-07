import SystemPackage
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct CopyFileReturn: RawRepresentable {
  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }
  init(_ rawValue: CInt) {
    self.rawValue = rawValue
  }
  public let rawValue: CInt

  /// The copy will continue as expected.
  public static var `continue`: Self { .init(COPYFILE_CONTINUE) }
  /// This object will be skipped, and the next object will be processed.  (Note that, when entering a directory, returning COPYFILE_SKIP from the call-back function will prevent the contents of the directory from being copied.)
  public static var skip: Self { .init(COPYFILE_SKIP) }
  /// The entire copy is aborted at this stage.  Any filesystem objects created up to this point will remain.  copyfile() will return -1, but errno will be unmodified.
  public static var quit: Self { .init(COPYFILE_QUIT) }
}

public struct CopyFileStage: RawRepresentable, Equatable {
  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }
  init(_ rawValue: CInt) {
    self.rawValue = rawValue
  }
  public let rawValue: CInt

  /// Before copying has begun.  The third parameter will be a newly-created copyfile_state_t object with the call-back function and context pre-loaded.
  public static var start: Self { .init(COPYFILE_START) }
  /// After copying has successfully finished.
  public static var finish: Self { .init(COPYFILE_FINISH) }
  /// Indicates an error has happened at some stage.  If the first argument to the call-back function is COPYFILE_RECURSE_ERROR, then an error occurred while processing the source hierarchy; otherwise, it will indicate what type of object was being copied, and errno will be set to indicate the error.
  public static var error: Self { .init(COPYFILE_ERR) }
  public static var progress: Self { .init(COPYFILE_PROGRESS) }
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
    state = copyfile_state_alloc()!
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
    guard let str = ptr else {
      return nil
    }
    return .init(cString: str)
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
  init(_ rawValue: CInt) {
    self.rawValue = rawValue
  }
  public let rawValue: CInt

  /// There was an error in processing an element of the source hierarchy; this happens when fts(3) returns an error or unknown file type.  (Currently, the second argu-ment to the call-back function will always be COPYFILE_ERR in this case.)
  public static var error: Self { .init(COPYFILE_RECURSE_ERROR) }

  /// The object being copied is a file (or, rather, something other than a directory).
  public static var file: Self { .init(COPYFILE_RECURSE_FILE) }

  /// The object being copied is a directory, and is being entered.  (That is, none of the filesystem objects contained within the directory have been copied yet.)
  public static var dir: Self { .init(COPYFILE_RECURSE_DIR) }
  /// The object being copied is a directory, and all of the objects contained have been copied.  At this stage, the destination directory being copied will have any extra permissions that were added to allow the copying will be removed.
  public static var dirCleanup: Self { .init(COPYFILE_RECURSE_DIR_CLEANUP) }

  public static var copyData: Self { .init(COPYFILE_COPY_DATA) }

  public static var copyXattr: Self { .init(COPYFILE_COPY_XATTR) }
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
  return context.callback?(.init(what), .init(stage), context).rawValue ?? COPYFILE_CONTINUE
}

extension FileUtility {

  public static func copyFile(from src: FilePath, to dst: FilePath, state: CopyFileState? = nil, flags: CopyFlags = []) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      src.withPlatformString { src in
        dst.withPlatformString { dst in
          copyfile(src, dst, state?.state, flags.rawValue)
        }
      }
    }.get()
  }

  public static func copyFile(from src: FileDescriptor, to dst: FileDescriptor, state: CopyFileState? = nil, flags: CopyFlags = []) throws {
    try nothingOrErrno(retryOnInterrupt: false) {
      fcopyfile(src.rawValue, dst.rawValue, state?.state, flags.rawValue)
    }.get()
  }

}

public struct CopyFlags: OptionSet {
  public init(rawValue: copyfile_flags_t) {
    self.rawValue = rawValue
  }
  init(_ rawValue: Int32) {
    self.rawValue = .init(rawValue)
  }
  public let rawValue: copyfile_flags_t

  public static var acl: Self { .init(COPYFILE_ACL) }
  public static var stat: Self { .init(COPYFILE_STAT) }
  public static var xattr: Self { .init(COPYFILE_XATTR) }
  public static var data: Self { .init(COPYFILE_DATA) }
  public static var security: Self { .init(COPYFILE_SECURITY) }
  public static var metadata: Self { .init(COPYFILE_METADATA) }
  public static var all: Self { .init(COPYFILE_ALL) }
  public static var recursive: Self { .init(COPYFILE_RECURSIVE) }
  public static var check: Self { .init(COPYFILE_CHECK) }
  public static var excl: Self { .init(COPYFILE_EXCL) }
  public static var nofollowSrc: Self { .init(COPYFILE_NOFOLLOW_SRC) }
  public static var nofollowDst: Self { .init(COPYFILE_NOFOLLOW_DST) }
  public static var move: Self { .init(COPYFILE_MOVE) }
  public static var unlink: Self { .init(COPYFILE_UNLINK) }
  public static var nofollow: Self { .init(COPYFILE_NOFOLLOW) }
  public static var pack: Self { .init(COPYFILE_PACK) }
  public static var unpack: Self { .init(COPYFILE_UNPACK) }
  public static var clone: Self { .init(COPYFILE_CLONE) }
  public static var cloneForce: Self { .init(COPYFILE_CLONE_FORCE) }
  public static var runInPlace: Self { .init(COPYFILE_RUN_IN_PLACE) }
  public static var dataSparse: Self { .init(COPYFILE_DATA_SPARSE) }
  public static var preserveDstTracked: Self { .init(COPYFILE_PRESERVE_DST_TRACKED) }
  public static var verbose: Self { .init(COPYFILE_VERBOSE) }
}

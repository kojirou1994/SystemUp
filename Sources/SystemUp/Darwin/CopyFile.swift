import SystemLibc
import SystemPackage
import CUtility

#if canImport(Darwin)

@usableFromInline
internal func copyfile_swift_callback(what: Int32, stage: Int32, state: copyfile_state_t?, src: UnsafePointer<CChar>?, dst: UnsafePointer<CChar>?, ctx: UnsafeMutableRawPointer?) -> Int32 {
  // Can't cast closure directly! Must use a Box! It's a compiler bug!
  /*
   bug code:
   struct Ref: ~Copyable {
   }
   var a: AnyObject!
   _ = a as! ((Int, borrowing Ref) -> Void)
   */
  let box = (Unmanaged<SystemCall.CopyFile.CallbackBox>.fromOpaque(ctx.unsafelyUnwrapped).takeUnretainedValue())
  let tempState = SystemCall.CopyFile.State(state: state.unsafelyUnwrapped)
  let result = box.callback(.init(rawValue: what), .init(rawValue: stage), tempState, src, dst).rawValue
  tempState.fakeRelease()
  return result
}

@usableFromInline
internal func copyfile_swift_callback_fall(what: Int32, stage: Int32, state: copyfile_state_t?, src: UnsafePointer<CChar>?, dst: UnsafePointer<CChar>?, ctx: UnsafeMutableRawPointer?) -> Int32 {
  assertionFailure("callback is invalid now!")
  return SystemCall.CopyFile.CallbackReturn.continue.rawValue
}

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copyFile(src: borrowing some CString, dst: borrowing some CString, flags: CopyFile.Flags = []) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      src.withUnsafeCString { src in
        dst.withUnsafeCString { dst in
          copyfile(src, dst, nil, flags.rawValue)
        }
      }
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copyFile(src: UnsafePointer<CChar>?, dst: UnsafePointer<CChar>?, state: borrowing CopyFile.State, flags: CopyFile.Flags = []) throws(Errno) {
    assert(src != nil || dst != nil, "neither src or dst must be set")
    try SyscallUtilities.voidOrErrno {
      copyfile(src, dst, state.state, flags.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copyFile(src: UnsafePointer<CChar>?, dst: UnsafePointer<CChar>?, state: borrowing CopyFile.State, flags: CopyFile.Flags = [], callback: CopyFile.NativeCallback) throws(Errno) {
    assert(state.callbackContext == nil && state.statusCallback == nil, "I'll set them for you!")
    try withoutActuallyEscaping(callback) { callback throws(Errno) in
      try withExtendedLifetime(CopyFile.CallbackBox(callback: callback)) { box throws(Errno) in
        let ctx = Unmanaged.passUnretained(box).toOpaque()
        state.callbackContext = ctx
        state.statusCallback = copyfile_swift_callback
        defer {
          // context is invalid but cannot set to nil!
          state.statusCallback = copyfile_swift_callback_fall
        }
        try copyFile(src: src, dst: dst, state: state, flags: flags)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copyFile(src: FileDescriptor, dst: FileDescriptor, flags: CopyFile.Flags = []) throws(Errno) {
    assert(
      CopyFile.Flags([.recursive, .exclusive, .noFollowSource,
                      .noFollowDestination, .noFollow, .move, .unlink,
                      .clone, .cloneForce])
      .intersection(flags).isEmpty, "has flags for path based copyfile")
    try SyscallUtilities.voidOrErrno {
      fcopyfile(src.rawValue, dst.rawValue, nil, flags.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copyFile(src: FileDescriptor, dst: FileDescriptor, state: borrowing CopyFile.State, flags: CopyFile.Flags = []) throws(Errno) {
    assert(
      CopyFile.Flags([.recursive, .exclusive, .noFollowSource,
                 .noFollowDestination, .noFollow, .move, .unlink,
                 .clone, .cloneForce])
      .intersection(flags).isEmpty, "has flags for path based copyfile")
    try SyscallUtilities.voidOrErrno {
      fcopyfile(src.rawValue, dst.rawValue, state.state, flags.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copyFile(src: FileDescriptor, dst: FileDescriptor, state: borrowing CopyFile.State, flags: CopyFile.Flags = [], callback: CopyFile.NativeCallback) throws(Errno) {
    assert(state.callbackContext == nil && state.statusCallback == nil, "I'll set them for you!")
    try withoutActuallyEscaping(callback) { callback throws(Errno) in
      try withExtendedLifetime(CopyFile.CallbackBox(callback: callback)) { box throws(Errno) in
        let ctx = Unmanaged.passUnretained(box).toOpaque()
        state.callbackContext = ctx
        state.statusCallback = copyfile_swift_callback
        defer {
          // context is invalid but cannot set to nil!
          state.statusCallback = copyfile_swift_callback_fall
        }
        try copyFile(src: src, dst: dst, state: state, flags: flags)
      }
    }
  }
}

extension SystemCall {
  public enum CopyFile {

    public typealias CCallback = copyfile_callback_t
    public typealias NativeCallback = (What, Stage, borrowing State, _ src: UnsafePointer<CChar>?, _ dst: UnsafePointer<CChar>?) -> CallbackReturn

    @usableFromInline
    internal final class CallbackBox {
      @usableFromInline
      let callback: SystemCall.CopyFile.NativeCallback
      @inlinable
      init(callback: @escaping SystemCall.CopyFile.NativeCallback) {
        self.callback = callback
      }
    }

    public struct CallbackReturn: RawRepresentable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: CInt) {
        self.rawValue = rawValue
      }

      public let rawValue: CInt

      /// The copy will continue as expected.
      @_alwaysEmitIntoClient
      public static var `continue`: Self { .init(rawValue: COPYFILE_CONTINUE) }
      /// This object will be skipped, and the next object will be processed.  (Note that, when entering a directory, returning COPYFILE_SKIP from the call-back function will prevent the contents of the directory from being copied.)
      @_alwaysEmitIntoClient
      public static var skip: Self { .init(rawValue: COPYFILE_SKIP) }
      /// The entire copy is aborted at this stage.  Any filesystem objects created up to this point will remain.  copyfile() will return -1, but errno will be unmodified.
      @_alwaysEmitIntoClient
      public static var quit: Self { .init(rawValue: COPYFILE_QUIT) }
    }

    public struct Stage: RawRepresentable, Equatable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: CInt) {
        self.rawValue = rawValue
      }

      public let rawValue: CInt

      /// Before copying has begun.  The third parameter will be a newly-created copyfile_state_t object with the call-back function and context pre-loaded.
      @_alwaysEmitIntoClient
      public static var start: Self { .init(rawValue: COPYFILE_START) }

      /// After copying has successfully finished.
      @_alwaysEmitIntoClient
      public static var finish: Self { .init(rawValue: COPYFILE_FINISH) }

      /// Indicates an error has happened at some stage.  If the first argument to the call-back function is COPYFILE_RECURSE_ERROR, then an error occurred while processing the source hierarchy; otherwise, it will indicate what type of object was being copied, and errno will be set to indicate the error.
      @_alwaysEmitIntoClient
      public static var error: Self { .init(rawValue: COPYFILE_ERR) }

      @_alwaysEmitIntoClient
      public static var progress: Self { .init(rawValue: COPYFILE_PROGRESS) }
    }

    public struct What: RawRepresentable, Equatable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: CInt) {
        self.rawValue = rawValue
      }

      public let rawValue: CInt

      /// There was an error in processing an element of the source hierarchy; this happens when fts(3) returns an error or unknown file type.  (Currently, the second argu-ment to the call-back function will always be COPYFILE_ERR in this case.)
      @_alwaysEmitIntoClient
      public static var error: Self { .init(rawValue: COPYFILE_RECURSE_ERROR) }

      /// The object being copied is a file (or, rather, something other than a directory).
      @_alwaysEmitIntoClient
      public static var file: Self { .init(rawValue: COPYFILE_RECURSE_FILE) }

      /// The object being copied is a directory, and is being entered.  (That is, none of the filesystem objects contained within the directory have been copied yet.)
      @_alwaysEmitIntoClient
      public static var directory: Self { .init(rawValue: COPYFILE_RECURSE_DIR) }

      /// The object being copied is a directory, and all of the objects contained have been copied.  At this stage, the destination directory being copied will have any extra permissions that were added to allow the copying will be removed.
      @_alwaysEmitIntoClient
      public static var directoryCleanup: Self { .init(rawValue: COPYFILE_RECURSE_DIR_CLEANUP) }

      @_alwaysEmitIntoClient
      public static var copyData: Self { .init(rawValue: COPYFILE_COPY_DATA) }

      @_alwaysEmitIntoClient
      public static var copyXattr: Self { .init(rawValue: COPYFILE_COPY_XATTR) }
    }

    public struct State: ~Copyable {

      @usableFromInline
      internal let state: copyfile_state_t

      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init() throws(Errno) {
        guard let state = copyfile_state_alloc() else {
          throw Errno.noMemory
        }
        self.state = state
      }

      @_alwaysEmitIntoClient @inlinable @inline(__always)
      deinit {
        copyfile_state_free(state)
      }

      @inlinable @inline(__always)
      internal init(state: copyfile_state_t) {
        self.state = state
      }

      @inlinable @inline(__always)
      internal consuming func fakeRelease() {
        discard self
      }

      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public func get(property: Propperty, _ value: UnsafeMutableRawPointer) -> Result<Void, Errno> {
        SyscallUtilities.voidOrErrno {
          copyfile_state_get(state, property.rawValue, value)
        }
      }

      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public func set(property: Propperty, _ value: UnsafeRawPointer) -> Result<Void, Errno> {
        // value must not be nil
        SyscallUtilities.voidOrErrno {
          copyfile_state_set(state, property.rawValue, value)
        }
      }

      public struct Propperty: MacroRawRepresentable, Equatable {
        @_alwaysEmitIntoClient @inlinable @inline(__always)
        public init(rawValue: UInt32) {
          self.rawValue = rawValue
        }

        public let rawValue: UInt32

        @_alwaysEmitIntoClient
        public static var srcFD: Self { .init(macroValue: COPYFILE_STATE_SRC_FD) }
        @_alwaysEmitIntoClient
        public static var dstFD: Self { .init(macroValue: COPYFILE_STATE_DST_FD) }
        @_alwaysEmitIntoClient
        public static var srcFilename: Self { .init(macroValue: COPYFILE_STATE_SRC_FILENAME) }
        @_alwaysEmitIntoClient
        public static var dstFilename: Self { .init(macroValue: COPYFILE_STATE_DST_FILENAME) }
        @_alwaysEmitIntoClient
        public static var statusCallback: Self { .init(macroValue: COPYFILE_STATE_STATUS_CB) }
        @_alwaysEmitIntoClient
        public static var callbackContext: Self { .init(macroValue: COPYFILE_STATE_STATUS_CTX) }
        @_alwaysEmitIntoClient
        public static var quarantine: Self { .init(macroValue: COPYFILE_STATE_QUARANTINE) }
        @_alwaysEmitIntoClient
        public static var copiedBytes: Self { .init(macroValue: COPYFILE_STATE_COPIED) }
        @_alwaysEmitIntoClient
        public static var xattrName: Self { .init(macroValue: COPYFILE_STATE_XATTRNAME) }
        @_alwaysEmitIntoClient
        public static var wasCloned: Self { .init(macroValue: COPYFILE_STATE_WAS_CLONED) }
        @_alwaysEmitIntoClient
        public static var srcBlockSize: Self { .init(macroValue: COPYFILE_STATE_SRC_BSIZE) }
        @_alwaysEmitIntoClient
        public static var dastBlockSize: Self { .init(macroValue: COPYFILE_STATE_DST_BSIZE) }
        @_alwaysEmitIntoClient
        public static var blockSize: Self { .init(macroValue: COPYFILE_STATE_BSIZE) }
        @_alwaysEmitIntoClient
        public static var forbidCrossMount: Self { .init(macroValue: COPYFILE_STATE_FORBID_CROSS_MOUNT) }
      }
    }

    public struct Flags: OptionSet, MacroRawRepresentable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
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
      public static var noFollowSource: Self { .init(macroValue: COPYFILE_NOFOLLOW_SRC) }

      /// Do not follow the to file, if it is a symbolic link.
      @_alwaysEmitIntoClient
      public static var noFollowDestination: Self { .init(macroValue: COPYFILE_NOFOLLOW_DST) }

      /// Unlink (using remove(3)) the from file. No error is returned if remove(3) fails.  Note that remove(3) removes a symbolic link itself, not the tar-get of the link.
      @_alwaysEmitIntoClient
      public static var move: Self { .init(macroValue: COPYFILE_MOVE) }

      /// Unlink the to file before starting.
      @_alwaysEmitIntoClient
      public static var unlink: Self { .init(macroValue: COPYFILE_UNLINK) }

      /// This is a convenience macro, equivalent to [.nofollowSrc, .nofollowDst].
      @_alwaysEmitIntoClient
      public static var noFollow: Self { .init(macroValue: COPYFILE_NOFOLLOW) }

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
  }
}

extension SystemCall.CopyFile.Stage: CustomStringConvertible {
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

extension SystemCall.CopyFile.What: CustomStringConvertible {
  public var description: String {
    switch self {
    case .file: return "file"
    case .directory: return "directory"
    case .error: return "error"
    case .directoryCleanup: return "directoryCleanup"
    case .copyData: return "copyData"
    case .copyXattr: return "copyXattr"
    default: return unknownDescription
    }
  }
}

public extension SystemCall.CopyFile.State {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func get<T: FixedWidthInteger>(property: Propperty) -> Result<T, Errno> {
    var result: T = 0
    return get(property: property, &result).map { result }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func get(property: Propperty) -> Result<Bool, Errno> {
    var result = false
    return get(property: property, &result).map { result }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func withUnsafeCString<R: ~Copyable, E: Error>(property: Propperty, _ body: (UnsafeMutablePointer<CChar>?) throws(E) -> R) throws(E) -> R {
    assert([.srcFilename, .dstFilename, .xattrName].contains(property))
    var ptr: UnsafeMutablePointer<CChar>?
    try! get(property: property, &ptr).get()
    return try body(ptr)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func set<T>(property: Propperty, value: T) -> Result<Void, Errno> {
    withUnsafeBytes(of: value) { buffer in
      set(property: property, buffer.baseAddress!)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  func set(property: Propperty, value: UnsafePointer<CChar>) -> Result<Void, Errno> {
    func set(_ property: Propperty, _ cString: UnsafePointer<CChar>) -> Result<Void, Errno> {
      self.set(property: property, UnsafeRawPointer(cString))
    }
    // string will be copied
    assert([.srcFilename, .dstFilename, .xattrName].contains(property))
    #if DEBUG
    /*
     fix:
     before set
     withUnsafeCString(property: property) { $0?.deallocate() }
     */
    withUnsafeCString(property: property) { string in
      if string != nil {
        fatalError("copyfile has memory leak, the old string will not be released!")
      }
    }
    #endif
    return set(property, value)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var callbackContext: UnsafeMutableRawPointer? {
    get {
      var result: UnsafeMutableRawPointer?
      return try! get(property: .callbackContext, &result).map { result }.get()
    }
    nonmutating set {
      if let newValue {
        try! set(property: .callbackContext, newValue).get()
      } else {
        assertionFailure("callbackContext cannot override by nil")
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var statusCallback: SystemCall.CopyFile.CCallback? {
    get {
      var result: UnsafeRawPointer?
      return try! get(property: .statusCallback, &result)
        .map { unsafeBitCast(result, to: SystemCall.CopyFile.CCallback?.self) }
        .get()
    }
    nonmutating set {
      if let newValue {
        try! set(property: .statusCallback, unsafeBitCast(newValue, to: UnsafeRawPointer.self)).get()
      } else {
        assertionFailure("statusCallback cannot override by nil")
      }
    }
  }

  /// Get the number of data bytes copied so far.  (Only valid for copyfile_state_get(); see below for more details about callbacks.)  If a COPYFILE_CLONE or COPYFILE_CLONE_FORCE operation successfully cloned the requested objects, then this value will be 0.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var copiedBytes: Int64 {
    try! get(property: .copiedBytes).get()
  }

  /// True if a COPYFILE_CLONE or COPYFILE_CLONE_FORCE operation successfully cloned the requested objects.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var wasCloned: Bool {
    try! get(property: .wasCloned).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var srcFD: FileDescriptor {
    get { .init(rawValue: try! get(property: .srcFD).get()) }
    nonmutating set { try! set(property: .srcFD, value: newValue.rawValue).get() }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var dstFD: FileDescriptor {
    get { .init(rawValue: try! get(property: .dstFD).get()) }
    nonmutating set { try! set(property: .dstFD, value: newValue.rawValue).get() }
  }

  @_alwaysEmitIntoClient @inlinable
  var src: FilePath? {
    withUnsafeCString(property: .srcFilename) { $0.map { FilePath(platformString: $0) } }
  }

  @_alwaysEmitIntoClient @inlinable
  var dst: FilePath? {
    withUnsafeCString(property: .dstFilename) { $0.map { FilePath(platformString: $0) } }
  }

}

//
//// High Level
////public final class CopyFileDelegate {
////
////  public typealias Callback = (CopyFileDelegate, SystemCall.CopyFile.What, SystemCall.CopyFile.Stage) -> SystemCall.CopyFile.CallbackReturn
////  private let state: SystemCall.CopyFile.State
////  public var callback: Callback?
////
////  public init() throws {
////    self.state = try .init()
////  }
////}

#endif // Darwin platform

#if os(Linux)
public extension SystemCall {
  /// Copy a range of data from one file to another
  /// - Parameters:
  ///   - inputFD: source file descriptor
  ///   - inputOffset:
  ///   - outputFD: target file descriptor
  ///   - outputOffset:
  ///   - length: bytes of data
  /// - Returns: the number of bytes copied between files.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copyFileRange(
    inputFD: FileDescriptor, inputOffset: UnsafeMutablePointer<Int>? = nil,
    outputFD: FileDescriptor, outputOffset: UnsafeMutablePointer<Int>? = nil,
    length: Int) -> Result<Int, Errno> {
    SyscallUtilities.valueOrErrno {
      /*
       The flags argument is provided to allow for future extensions and
       currently must be set to 0.
       */
      SystemLibc.copy_file_range(inputFD.rawValue, inputOffset, outputFD.rawValue, outputOffset, length, 0)
    }
  }
}
#endif

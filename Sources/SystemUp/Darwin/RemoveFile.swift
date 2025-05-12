import SystemLibc
import SystemPackage
import CUtility

#if canImport(Darwin)

@usableFromInline
internal func removefile_swift_callback(state: removefile_state_t!, path: UnsafePointer<CChar>!, ctx: UnsafeMutableRawPointer!) -> Int32 {
  assert(state != nil, "impossible")
  assert(path != nil, "impossible")
  assert(ctx != nil, "context not set!")
  let tempState = SystemCall.RemoveFile.State(state: state.unsafelyUnwrapped)
  let result = DynamicCString.withTemporaryBorrowed(cString: path) { path in
    UnsafeRawPointer(ctx).assumingMemoryBound(to: SystemCall.RemoveFile.NativeCallback.self)
      .pointee(tempState, path).rawValue
  }
  tempState.fakeRelease()
  return result
}

public extension SystemCall {

  @_alwaysEmitIntoClient @inline(__always)
  private static func _removeFile(path: borrowing some CStringConvertible & ~Copyable, relativeTo base: RelativeDirectory = .cwd, state: removefile_state_t?, flags: RemoveFile.Flags = []) throws(Errno) {
    let code = path.withUnsafeCString { path in
      switch base {
      case .cwd:
        // a little faster: https://github.com/apple-oss-distributions/removefile/blob/e8685c65267b1def76a63d0fffd6d646faed795e/removefile.c#L255
        SystemLibc.removefile(path, state, flags.rawValue)
      case .directory(let baseFD):
        SystemLibc.removefileat(baseFD.rawValue, path, state, flags.rawValue)
      }
    }
    if code != 0 {
      assert(code < 0, "from man page")
      throw Errno.systemCurrent
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func removeFile(path: borrowing some CStringConvertible & ~Copyable, relativeTo base: RelativeDirectory = .cwd, flags: RemoveFile.Flags = []) throws(Errno) {
    try _removeFile(path: path, relativeTo: base, state: nil, flags: flags)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func removeFile(path: borrowing some CStringConvertible & ~Copyable, relativeTo base: RelativeDirectory = .cwd, state: borrowing RemoveFile.State, flags: RemoveFile.Flags = []) throws(Errno) {
    try withExtendedLifetime(state) { state throws(Errno) in
      try _removeFile(path: path, relativeTo: base, state: state.state, flags: flags)
    }
  }

  /// Example Usage of RemoveFile
  @_alwaysEmitIntoClient
  static func removeFile(path: borrowing some CStringConvertible & ~Copyable, relativeTo base: RelativeDirectory = .cwd, flags: RemoveFile.Flags = [], statusCallback: @escaping RemoveFile.NativeCallback, confirmCallback: @escaping RemoveFile.NativeCallback, errorCallback: @escaping RemoveFile.NativeCallback) throws(Errno) {
    var state = try RemoveFile.State()
    //   assert(state.callbackContext == nil && state.statusCallback == nil, "I'll set them for you!")
    try! state.set(property: .statusCallback, unsafeBitCast(removefile_swift_callback as removefile_callback_t, to: UnsafeRawPointer.self))
    try! state.set(property: .confirmCallback, unsafeBitCast(removefile_swift_callback as removefile_callback_t, to: UnsafeRawPointer.self))
    try! state.set(property: .errorCallback, unsafeBitCast(removefile_swift_callback as removefile_callback_t, to: UnsafeRawPointer.self))
    #if false
    // state is local so no cleanup yet
    defer {
      var value: UnsafeRawPointer?
      try! state.set(property: .confirmCallback, nil)
      try! state.set(property: .confirmContext, &value)
      #if Xcode
      try! state.get(property: .confirmCallback, &value)
      precondition(value == nil)
      try! state.get(property: .confirmContext, &value)
      precondition(value == nil)
      #endif
    }
    #endif

    try withExtendedLifetime(statusCallback) { statusCallback throws(Errno) in
      try withUnsafePointer(to: statusCallback) { statusContext throws(Errno) in
        try! state.set(property: .statusContext, statusContext)
        try withExtendedLifetime(confirmCallback) { confirmCallback throws(Errno) in
          try withUnsafePointer(to: confirmCallback) { confirmContext throws(Errno) in
            try! state.set(property: .confirmContext, confirmContext)
            try withExtendedLifetime(errorCallback) { errorCallback throws(Errno) in
              try withUnsafePointer(to: errorCallback) { errorContext throws(Errno) in
                try! state.set(property: .errorContext, errorContext)
                try removeFile(path: path, relativeTo: base, state: state, flags: flags)
              }
            }
          }
        }
      }
    }

  }

}

extension SystemCall {
  public enum RemoveFile {

    public typealias NativeCallback = (borrowing State, borrowing DynamicCString) -> CallbackReturn

    // State object to pass in callback information
    public struct State: ~Copyable {

      @usableFromInline
      internal let state: removefile_state_t

      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init() throws(Errno) {
        guard let state = removefile_state_alloc() else {
          throw Errno.noMemory
        }
        self.state = state
      }

      @_alwaysEmitIntoClient @inlinable @inline(__always)
      deinit {
        removefile_state_free(state)
      }

      @inlinable @inline(__always)
      internal init(state: removefile_state_t) {
        self.state = state
      }

      @inlinable @inline(__always)
      internal consuming func fakeRelease() {
        discard self
      }

      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public func get(property: Propperty, to value: UnsafeMutableRawPointer) throws(Errno) {
        try SyscallUtilities.voidOrErrno {
          removefile_state_get(state, property.rawValue, value)
        }.get()
      }

      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public mutating func set(property: Propperty, _ value: UnsafeRawPointer?) throws(Errno) {
        // value can be nil
        try SyscallUtilities.voidOrErrno {
          removefile_state_set(state, property.rawValue, value)
        }.get()
      }

      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public func cancel() {
        let code = removefile_cancel(state)
        assert(code == 0)
      }

      public struct Propperty {
        @_alwaysEmitIntoClient @inlinable @inline(__always)
        public init(rawValue: Int) {
          self.rawValue = UInt32(rawValue)
        }
        public let rawValue: UInt32
      }
    }

    public struct CallbackReturn {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }
      public let rawValue: Int32
    }

    public struct Flags: OptionSet, MacroRawRepresentable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: removefile_flags_t) {
        self.rawValue = rawValue
      }
      public let rawValue: removefile_flags_t
    }
  }
}

public extension SystemCall.RemoveFile.State {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  var error: Errno {
    var e: Int32 = Memory.undefined()
    try! get(property: .errno, to: &e)
    return .init(rawValue: e)
  }

  var ftsEntry: Fts.Entry {
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    get throws {
      let v: UnsafeMutablePointer<FTSENT> = try safeInitialize { ptr in
        try get(property: .ftsent, to: &ptr)
      }
      return .init(v)
    }
  }
}

public extension SystemCall.RemoveFile.State.Propperty {
  /// Get or set the callback function of type removefile_callback_t to be called prior to file deletion.
  @_alwaysEmitIntoClient
  static var confirmCallback: Self { .init(rawValue: REMOVEFILE_STATE_CONFIRM_CALLBACK) }

  /// Get or set any parameters of type void * that are needed for the confirm callback function.
  @_alwaysEmitIntoClient
  static var confirmContext: Self { .init(rawValue: REMOVEFILE_STATE_CONFIRM_CONTEXT) }

  /// Get or set the callback function of type removefile_callback_t to be called when an error is detected.
  @_alwaysEmitIntoClient
  static var errorCallback: Self { .init(rawValue: REMOVEFILE_STATE_ERROR_CALLBACK) }

  /// Get or set any parameters of type void * that are needed for the error callback function.
  @_alwaysEmitIntoClient
  static var errorContext: Self { .init(rawValue: REMOVEFILE_STATE_ERROR_CONTEXT) }

  /// Get or set the current errno of type int
  @_alwaysEmitIntoClient
  static var errno: Self { .init(rawValue: REMOVEFILE_STATE_ERRNO) }

  /// Get or set the callback function of type removefile_callback_t to be called subsequent to file deletion.
  @_alwaysEmitIntoClient
  static var statusCallback: Self { .init(rawValue: REMOVEFILE_STATE_STATUS_CALLBACK) }

  /// Get or set any parameters of type void * that are needed for the status callback function.
  @_alwaysEmitIntoClient
  static var statusContext: Self { .init(rawValue: REMOVEFILE_STATE_STATUS_CONTEXT) }

  /// Get any available file entry information of type FTSENT * (setting is not allowed).
  @_alwaysEmitIntoClient
  static var ftsent: Self { .init(rawValue: REMOVEFILE_STATE_FTSENT) }
}

public extension SystemCall.RemoveFile.CallbackReturn {
  /// File is deleted and removefile() continues operation as normal.
  @_alwaysEmitIntoClient
  static var proceed: Self { .init(rawValue: Int32(REMOVEFILE_PROCEED)) }

  /// Current file is not deleted and removefile() continues operation as normal.
  @_alwaysEmitIntoClient
  static var skip: Self { .init(rawValue: Int32(REMOVEFILE_SKIP)) }

  /// Current file is not deleted and removefile() exits without continuing further.
  @_alwaysEmitIntoClient
  static var stop: Self { .init(rawValue: Int32(REMOVEFILE_STOP)) }
}

public extension SystemCall.RemoveFile.Flags {
  /// If the path location is a directory, then recursively delete the entire directory.
  @_alwaysEmitIntoClient
  static var recursive: Self { .init(macroValue: REMOVEFILE_RECURSIVE) }

  /// The file or directory at the path location is not deleted.  If specified in conjunction with
  /// REMOVEFILE_RECURSIVE, then all of the contents of the directory at path location will be
  /// deleted, but not the directory itself.
  @_alwaysEmitIntoClient
  static var keepParent: Self { .init(macroValue: REMOVEFILE_KEEP_PARENT) }

  /// By default, recursive traversals do not cross mount points.  This option allows removefile()
  /// to descend into directories that have a different device number than the file from which the
  /// descent began.
  @_alwaysEmitIntoClient
  static var crossMount: Self { .init(macroValue: REMOVEFILE_CROSS_MOUNT) }

  /// Overwrite with a single pass of zeroes.
  @_alwaysEmitIntoClient
  static var secure1PassZero: Self { .init(macroValue: REMOVEFILE_SECURE_1_PASS_ZERO) }

  /// Overwrite with a single pass of random data.
  @_alwaysEmitIntoClient
  static var secure1Pass: Self { .init(macroValue: REMOVEFILE_SECURE_1_PASS) }

  /// Overwrite the file twice with random bytes, and then with 0xAA.
  @_alwaysEmitIntoClient
  static var secure3Pass: Self { .init(macroValue: REMOVEFILE_SECURE_3_PASS) }

  /// Overwrite the file with 7 US DoD compliant passes (0xF6, 0x00,  0xFF,  random, 0x00, 0xFF, random).
  @_alwaysEmitIntoClient
  static var secure7Pass: Self { .init(macroValue: REMOVEFILE_SECURE_7_PASS) }

  /// Overwrite the file using 35-pass Gutmann algorithm.
  @_alwaysEmitIntoClient
  static var secure35Pass: Self { .init(macroValue: REMOVEFILE_SECURE_35_PASS) }

  /// Allow paths traversed internally to exceed the PATH_MAX constant.  This requires changing the
  /// working directory of the process that has called into removefile() temporarily. (This does
  /// not remove the requirement that no component of the path location exceeds NAME_MAX
  /// characters, nor does it allow the path argument itself to exceed PATH_MAX.)
  @_alwaysEmitIntoClient
  static var allowLongPaths: Self { .init(macroValue: REMOVEFILE_ALLOW_LONG_PATHS) }

  /// Clear purgeable on any directory encountered before deletion
  @_alwaysEmitIntoClient
  static var clearPurgeable: Self { .init(macroValue: REMOVEFILE_CLEAR_PURGEABLE) }

  /// File Discarded by system
  @_alwaysEmitIntoClient
  static var systemDiscarded: Self { .init(macroValue: REMOVEFILE_SYSTEM_DISCARDED) }

  /// Slim implementation of dir removal, which iterates the directory in DFS, to reduce memory consumption.
  @_alwaysEmitIntoClient
  static var recursiveSlim: Self { .init(macroValue: REMOVEFILE_RECURSIVE_SLIM) }
}

#endif

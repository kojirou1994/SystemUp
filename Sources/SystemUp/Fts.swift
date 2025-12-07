import CUtility
import SystemLibc

public struct Fts: ~Copyable {
  @_alwaysEmitIntoClient
  internal init(_ handle: UnsafeMutablePointer<FTS>) {
    self.handle = handle
  }

  @usableFromInline
  internal let handle: UnsafeMutablePointer<FTS>

  @_alwaysEmitIntoClient
  public static func open(path: borrowing some CString, options: OpenOptions) throws(Errno) -> Self {
    try withUnsafeTemporaryAllocationTyped(of: UnsafeMutablePointer<Int8>?.self, capacity: 2) { array throws(Errno) in
      try path.withUnsafeCString { path throws(Errno) in
        array[0] = .init(mutating: path)
        array[1] = nil
        return try ftsOpen(array.baseAddress.unsafelyUnwrapped, options)
      }
    }
  }

  /// empty paths will crash
  @_alwaysEmitIntoClient
  public static func open(paths: some Collection<some ContiguousUTF8Bytes>, options: OpenOptions) throws(Errno) -> Self {
    try withTempUnsafeCStringArray(paths) { argv throws(Errno) in
      try ftsOpen(argv, options)
    }
  }

  @_alwaysEmitIntoClient
  public static func open(paths: borrowing CStringArray, options: OpenOptions) throws(Errno) -> Self {
    try paths.withUnsafeCArrayPointer { array throws(Errno) in
      try ftsOpen(array, options)
    }
  }

  @_alwaysEmitIntoClient
  public static func ftsOpen(_ array: UnsafePointer<UnsafeMutablePointer<CChar>?>, _ options: OpenOptions) throws(Errno) -> Self {
    assert(options.contains(.logical) || options.contains(.physical), "at least one of which (either FTS_LOGICAL or FTS_PHYSICAL) must be specified")

    return .init(try SyscallUtilities.unwrap {
      fts_open(array, options.rawValue, nil)
    }.get())
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  private func entryOrErrno(_ ptr: UnsafeMutablePointer<FTSENT>?) throws(Errno) -> Fts.Entry? {
    if let ptr = ptr {
      return _overrideLifetime(.init(ptr), borrowing: self)
    }
    if let errno = Errno.systemCurrentValid {
      throw errno
    }
    return nil
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  @_lifetime(borrow self)
  public func read() throws(Errno) -> Fts.Entry? {
    try entryOrErrno(fts_read(handle))
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  @_lifetime(borrow self)
  public func children(options: ChildrenOptions = []) throws(Errno) -> Fts.Entry? {
    try entryOrErrno(fts_children(handle, options.rawValue))
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public func set(entry: Fts.Entry, option: SetOption) throws(Errno) {
    try SyscallUtilities.voidOrErrno {
      fts_set(handle, entry.rawAddress, option.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  deinit {
    assertNoFailure {
      SyscallUtilities.voidOrErrno {
        fts_close(handle)
      }
    }
  }

}

extension Fts {

  public struct OpenOptions: OptionSet, MacroRawRepresentable {

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// This option causes any symbolic link specified as a root path to be followed immediately whether or not
    /// FTS_LOGICAL is also specified.
    @_alwaysEmitIntoClient
    public static var comFollow: Self { .init(macroValue: FTS_COMFOLLOW) }

    /// This option causes the fts routines to return FTSENT structures for the targets of symbolic links instead of
    /// the symbolic links themselves.  If this option is set, the only symbolic links for which FTSENT structures
    /// are returned to the application are those referencing non-existent files.  Either FTS_LOGICAL or FTS_PHYSICAL
    /// must be provided to the fts_open() function.
    @_alwaysEmitIntoClient
    public static var logical: Self { .init(macroValue: FTS_LOGICAL) }

    /// As a performance optimization, the fts functions change directories as they walk the file hierarchy.  This
    /// has the side-effect that an application cannot rely on being in any particular directory during the traver-
    /// sal.  The FTS_NOCHDIR option turns off this optimization, and the fts functions will not change the current
    /// directory.  Note that applications should not themselves change their current directory and try to access
    /// files unless FTS_NOCHDIR is specified and absolute pathnames were provided as arguments to fts_open().
    @_alwaysEmitIntoClient
    public static var noChdir: Self { .init(macroValue: FTS_NOCHDIR) }

    /// By default, returned FTSENT structures reference file characteristic information (the statp field) for each
    /// file visited.  This option relaxes that requirement as a performance optimization, not calling stat(2) when-
    /// ever possible.  If stat(2) doesn't need to be called, the fts functions will set the fts_info field to
    /// FTS_NSOK; otherwise fts_info will be set to the correct file information value corresponding to the stat(2)
    /// information.  In any case, the statp field will always be undefined.  Note that because fts detects directory
    /// cycles and dangling symbolic links, stat(2) is always called for directories and is called for symbolic links
    /// when FTS_LOGICAL is set.
    @_alwaysEmitIntoClient
    public static var noStat: Self { .init(macroValue: FTS_NOSTAT) }

    /// Like FTS_NOSTAT but if the file type is returned by readdir(3), the corresponding file information value is
    /// returned in fts_info instead of FTS_NSOK.
    #if APPLE
    @_alwaysEmitIntoClient
    public static var noStatType: Self { .init(macroValue: FTS_NOSTAT_TYPE) }
    #endif

    /// This option causes the fts routines to return FTSENT structures for symbolic links themselves instead of the
    /// target files they point to.  If this option is set, FTSENT structures for all symbolic links in the hierarchy
    /// are returned to the application.  Either FTS_LOGICAL or FTS_PHYSICAL must be provided to the fts_open() function.
    @_alwaysEmitIntoClient
    public static var physical: Self { .init(macroValue: FTS_PHYSICAL) }

    /// By default, unless they are specified as path arguments to fts_open(), any files named `.' or `..' encoun-
    /// tered in the file hierarchy are ignored.  This option causes the fts routines to return FTSENT structures for them.
    @_alwaysEmitIntoClient
    public static var seeDot: Self { .init(macroValue: FTS_SEEDOT) }

    /// This option prevents fts from descending into directories that have a different device number than the file
    /// from which the descent began.
    @_alwaysEmitIntoClient
    public static var excludeDifferentDevice: Self { .init(macroValue: FTS_XDEV) }

  }

}

extension Fts {

  public enum Level {

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public static var rootParent: Int16 {
      .init(FTS_ROOTPARENTLEVEL)
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public static var root: Int16 {
      .init(FTS_ROOTLEVEL)
    }

    #if APPLE
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public static var max: Int16 {
      .init(FTS_MAXLEVEL)
    }
    #endif
  }

  public struct Entry: ~Escapable {
    @_alwaysEmitIntoClient
    internal init(_ rawAddress: UnsafeMutablePointer<FTSENT>) {
      self.rawAddress = rawAddress
    }

    public struct Identifier: Equatable {
      @usableFromInline
      internal let rawAddress: UnsafeMutablePointer<FTSENT>
      @_alwaysEmitIntoClient
      internal init(_ rawAddress: UnsafeMutablePointer<FTSENT>) {
        self.rawAddress = rawAddress
      }
    }

    @usableFromInline
    internal let rawAddress: UnsafeMutablePointer<FTSENT>

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var identifier: Identifier {
      .init(rawAddress)
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var info: Info {
      .init(rawValue: rawAddress.pointee.fts_info)
    }

    /// A path for accessing the file from the current directory.
    public var pathToCurrentDirectory: ReferenceCString {
      @_lifetime(borrow self)
      @_transparent
      borrowing get {
        _overrideLifetime(.init(cString: rawAddress.pointee.fts_accpath), borrowing: self)
      }
    }
    
    /// The path for the file relative to the root of the traversal.  This path contains the path specified to fts_open() as a prefix.
    public var path: ReferenceCString {
      @_lifetime(borrow self)
      @_transparent
      borrowing get {
        _overrideLifetime(.init(cString: rawAddress.pointee.fts_path), borrowing: self)
      }
    }

    public var nameCString: ReferenceCString {
      @_lifetime(borrow self)
      @_transparent
      borrowing get {
        return _overrideLifetime(ReferenceCString(cString: swift_ftsent_getname(rawAddress)), borrowing: self)
      }
    }

    @_alwaysEmitIntoClient
    public var name: String {
      nameCString.withUnsafeCString { cString in
        String(decoding: UnsafeRawBufferPointer(start: cString, count: Int(nameLength)), as: UTF8.self)
      }
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var isHidden: Bool {
      rawAddress.pointee.fts_name == UInt8(ascii: ".")
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var nameLength: UInt16 {
      rawAddress.pointee.fts_namelen
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var level: Int16 {
      rawAddress.pointee.fts_level
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var errno: Errno? {
      rawAddress.pointee.fts_errno == 0 ? nil : .init(rawValue: rawAddress.pointee.fts_errno)
    }

    /// local numeric value
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var number: Int {
      get {
        rawAddress.pointee.fts_number
      }
      nonmutating _modify {
        yield &rawAddress.pointee.fts_number
      }
    }

    /// local address value
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var pointer: UnsafeMutableRawPointer? {
      get {
        rawAddress.pointee.fts_pointer
      }
      nonmutating _modify {
        yield &rawAddress.pointee.fts_pointer
      }
    }


    public var parentDirectory: Self {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      @_lifetime(borrow self)
      get {
        .init(rawAddress.pointee.fts_parent)
      }
    }

    /// next file in directory
    public var nextFile: Self? {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      @_lifetime(borrow self)
      get {
        guard let p = rawAddress.pointee.fts_link else {
          return nil
        }
        return _overrideLifetime(.init(p), borrowing: self)
      }
    }

    public var cycleNode: Self? {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      @_lifetime(borrow self)
      get {
        guard let p = rawAddress.pointee.fts_cycle else {
          return nil
        }
        return _overrideLifetime(.init(p), borrowing: self)
      }
    }

    /// fd for symlink or chdir
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var symbolicFileDescriptor: FileDescriptor {
      .init(rawValue: rawAddress.pointee.fts_symfd)
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var inode: CInterop.UpInodeNumber {
      rawAddress.pointee.fts_ino
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var device: DeviceID {
      .init(rawValue: rawAddress.pointee.fts_dev)
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var linkCount: CInterop.UpNumberOfLinks {
      rawAddress.pointee.fts_nlink
    }

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var fileStatus: UnsafePointer<FileStatus>? {
      .init(OpaquePointer(rawAddress.pointee.fts_statp))
    }

  }

  public struct ChildrenOptions: OptionSet, MacroRawRepresentable {

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// Only the names of the files are needed.  The contents of all the fields in the returned linked list of struc-
    /// tures are undefined with the exception of the fts_name and fts_namelen fields.
    @_alwaysEmitIntoClient
    public static var nameOnly: Self { .init(macroValue: FTS_NAMEONLY) }
  }

  public struct SetOption: MacroRawRepresentable {

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// Re-visit the file; any file type may be re-visited.  The next call to fts_read() will return the referenced
    /// file.  The fts_stat and fts_info fields of the structure will be reinitialized at that time, but no other fields
    /// will have been changed.  This option is meaningful only for the most recently returned file from fts_read().
    /// Normal use is for post-order directory visits, where it causes the directory to be re-visited (in both pre and
    /// post-order) as well as all of its descendants.
    @_alwaysEmitIntoClient
    public static var again: Self { .init(macroValue: FTS_AGAIN) }

    /// The referenced file must be a symbolic link.  If the referenced file is the one most recently returned by
    /// fts_read(), the next call to fts_read() returns the file with the fts_info and fts_statp fields reinitialized to
    /// reflect the target of the symbolic link instead of the symbolic link itself.  If the file is one of those most
    /// recently returned by fts_children(), the fts_info and fts_statp fields of the structure, when returned by
    /// fts_read(), will reflect the target of the symbolic link instead of the symbolic link itself.  In either case,
    /// if the target of the symbolic link does not exist the fields of the returned structure will be unchanged and the
    /// fts_info field will be set to FTS_SLNONE.
    /// If the target of the link is a directory, the pre-order return, followed by the return of all of its descen-
    /// dants, followed by a post-order return, is done.
    @_alwaysEmitIntoClient
    public static var follow: Self { .init(macroValue: FTS_FOLLOW) }

    /// No descendants of this file are visited.  The file may be one of those most recently returned by either
    /// fts_children() or fts_read().
    @_alwaysEmitIntoClient
    public static var skip: Self { .init(macroValue: FTS_SKIP) }
  }

  public struct Info: MacroRawRepresentable, Equatable {

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: UInt16) {
      self.rawValue = rawValue
    }

    public let rawValue: UInt16

    /// A directory being visited in pre-order.
    @_alwaysEmitIntoClient
    public static var directoryPre: Self { .init(macroValue: FTS_D) }

    /// A directory that causes a cycle in the tree.  (The fts_cycle field of the FTSENT structure will be filled in as well.)
    @_alwaysEmitIntoClient
    public static var directoryCycle: Self { .init(macroValue: FTS_DC) }

    /// Any FTSENT structure that represents a file type not explicitly described by one of the other fts_info values.
    @_alwaysEmitIntoClient
    public static var `default`: Self { .init(macroValue: FTS_DEFAULT) }

    /// A directory which cannot be read.  This is an error return, and the fts_errno field will be set to indicate what caused the error.
    @_alwaysEmitIntoClient
    public static var directoryNotRead: Self { .init(macroValue: FTS_DNR) }

    /// A file named ‘.’ or ‘..’ which was not specified as a file name to fts_open() or fts_open_b() (see FTS_SEEDOT).
    @_alwaysEmitIntoClient
    public static var dot: Self { .init(macroValue: FTS_DOT) }

    /// A directory being visited in post-order.  The contents of the FTSENT structure will be unchanged from when it was returned in pre-order, i.e. with the fts_info field set to FTS_D.
    @_alwaysEmitIntoClient
    public static var directoryPost: Self { .init(macroValue: FTS_DP) }

    /// This is an error return, and the fts_errno field will be set to indicate what caused the error.
    @_alwaysEmitIntoClient
    public static var error: Self { .init(macroValue: FTS_ERR) }

    /// A regular file.
    @_alwaysEmitIntoClient
    public static var file: Self { .init(macroValue: FTS_F) }

    /// A file for which no stat(2) information was available.  The contents of the fts_statp field are undefined.  This is an error return, and the fts_errno field will be set to indicate what caused the error.
    @_alwaysEmitIntoClient
    public static var fileNoStat: Self { .init(macroValue: FTS_NS) }

    /// A file for which no stat(2) information was requested.  The contents of the fts_statp field are undefined.
    @_alwaysEmitIntoClient
    public static var fileNoStatRequested: Self { .init(macroValue: FTS_NSOK) }

    /// A symbolic link.
    @_alwaysEmitIntoClient
    public static var symbolic: Self { .init(macroValue: FTS_SL) }

    /// A symbolic link with a non-existent target.  The contents of the fts_statp field reference the file characteristic information for the symbolic link itself.
    @_alwaysEmitIntoClient
    public static var symbolicNonExistent: Self { .init(macroValue: FTS_SLNONE) }

  }

}

extension Fts.Info: CustomStringConvertible {
  public var description: String {
    switch self {
    case .default: "Any FTSENT structure that represents a file type not explicitly described by one of the other fts_info values."
    case .dot: "A file named ‘.’ or ‘..’ which was not specified as a file name to fts_open() or fts_open_b()."
    case .directoryPre: " directory being visited in pre-order."
    case .directoryPost: "A directory being visited in post-order."
    case .directoryCycle: "A directory that causes a cycle in the tree."
    case .file: "A regular file."
    case .fileNoStatRequested: "A file for which no stat(2) information was requested."
    case .symbolic: "A symbolic link."
    case .symbolicNonExistent: "A symbolic link with a non-existent target."
    case .fileNoStat: "(Error)A file for which no stat(2) information was available."
    case .directoryNotRead: "(Error)A directory which cannot be read."
    case .error: "(Error)This is an error return."
    default: "unknown(\(rawValue))"
    }
  }
}

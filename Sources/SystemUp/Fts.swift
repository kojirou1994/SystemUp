import SystemPackage
import CSystemUp
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct Fts {
  private init(_ handle: UnsafeMutablePointer<FTS>) {
    self.handle = handle
  }

  private let handle: UnsafeMutablePointer<FTS>

  public static func open(path: FilePath, options: OpenOptions = []) -> Result<Self, Errno> {
    path.withPlatformString { path in
      var array: (UnsafeMutablePointer<Int8>?, UnsafeMutablePointer<Int8>?) = (UnsafeMutablePointer(mutating: path), nil)
      return withUnsafeMutableBytes(of: &array) { pointer in
        _fts_open(pointer.baseAddress?.assumingMemoryBound(to: UnsafeMutablePointer<Int8>?.self), options)
      }
    }
  }

  public static func open<C: Collection>(paths: C, options: OpenOptions = []) -> Result<Self, Errno> where C.Element == FilePath {

    let arraySize = paths.count + 1
    let pathArray = UnsafeMutableBufferPointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: arraySize)
    pathArray.initialize(repeating: nil)
    defer {
      pathArray.dropLast().forEach { $0?.deallocate() }
      pathArray.initialize(repeating: nil)
      pathArray.deallocate()
    }
    paths.enumerated().forEach { offset, path in
      path.withPlatformString { path in
        pathArray[offset] = strdup(path)
      }
    }

    return _fts_open(pathArray.baseAddress, options)
  }

  internal static func _fts_open(_ array: UnsafePointer<UnsafeMutablePointer<CChar>?>?, _ options: OpenOptions) -> Result<Self, Errno> {
    assert(options.contains(.logical) || options.contains(.physical), "at least one of which (either FTS_LOGICAL or FTS_PHYSICAL) must be specified")

    guard let ptr = fts_open(array, options.rawValue, nil) else {
      return .failure(Errno.current)
    }
    return .success(.init(ptr))
  }

  private func entryOrErrno(_ ptr: UnsafeMutablePointer<FTSENT>?) throws -> Fts.Entry? {
    if let ptr = ptr {
      return .init(ptr)
    }
    let errno = Errno.current
    if errno.rawValue != 0 {
      throw errno
    }
    return nil
  }

  public func read() -> Fts.Entry? {
    fts_read(handle).map(Fts.Entry.init)
  }

  public func children(options: ChildrenOptions = []) throws -> Fts.Entry? {
    try entryOrErrno(fts_children(handle, options.rawValue))
  }

  public func set(entry: Fts.Entry, option: SetOption) throws {
    try voidOrErrno {
      fts_set(handle, entry.ptr, option.rawValue)
    }.get()
  }

  public func close() {
    neverError {
      voidOrErrno {
        fts_close(handle)
      }
    }
  }

  public func closeAfter<R>(_ body: (Self) throws -> R) rethrows -> R {
    defer { close() }
    return try body(self)
  }
}

extension Fts {

  public struct OpenOptions: OptionSet {

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
    #if canImport(Darwin)
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

    public static var rootParent: Int16 {
      .init(FTS_ROOTPARENTLEVEL)
    }

    public static var root: Int16 {
      .init(FTS_ROOTLEVEL)
    }

    #if canImport(Darwin)
    public static var max: Int16 {
      .init(FTS_MAXLEVEL)
    }
    #endif
  }

  public struct Entry {
    fileprivate init(_ ptr: UnsafeMutablePointer<FTSENT>) {
      self.ptr = ptr
    }

    fileprivate let ptr: UnsafeMutablePointer<FTSENT>

    public var info: Info {
      .init(rawValue: ptr.pointee.fts_info)
    }

    public var pathToCurrentDirectory: FilePath {
      .init(platformString: ptr.pointee.fts_accpath)
    }

    public var path: FilePath {
      .init(platformString: ptr.pointee.fts_path)
    }

    public var name: String {
      #if compiler(>=5.7) && !os(macOS)
      .init(cString: ptr.pointer(to: \.fts_name).unsafelyUnwrapped)
      #else
      .init(cString: &ptr.pointee.fts_name)
      #endif
    }

    public var nameLength: UInt16 {
      ptr.pointee.fts_namelen
    }

    public var level: Int16 {
      ptr.pointee.fts_level
    }

    public var errno: Errno? {
      ptr.pointee.fts_errno == 0 ? nil : .init(rawValue: ptr.pointee.fts_errno)
    }

    /// local numeric value
    public var number: Int {
      get {
        ptr.pointee.fts_number
      }
      nonmutating _modify {
        yield &ptr.pointee.fts_number
      }
    }

    /// local address value
    public var pointer: UnsafeMutableRawPointer? {
      get {
        ptr.pointee.fts_pointer
      }
      nonmutating _modify {
        yield &ptr.pointee.fts_pointer
      }
    }

    public var parentDirectory: Self {
      .init(ptr.pointee.fts_parent)
    }

    /// next file in directory
    public var nextFile: Self? {
      ptr.pointee.fts_link.map { .init($0) }
    }

    public var cycleNode: Self? {
      ptr.pointee.fts_cycle.map { .init($0) }
    }

    /// fd for symlink or chdir
    public var symbolicFileDescriptor: FileDescriptor {
      .init(rawValue: ptr.pointee.fts_symfd)
    }
    public var inode: ino_t {
      ptr.pointee.fts_ino
    }

    public var device: dev_t {
      ptr.pointee.fts_dev
    }

    public var linkCount: CInterop.UpNumberOfLinks {
      ptr.pointee.fts_nlink
    }

    public var fileStatus: UnsafePointer<FileStatus>? {
      .init(OpaquePointer(ptr.pointee.fts_statp))
    }

  }

  public struct ChildrenOptions: OptionSet {

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    /// Only the names of the files are needed.  The contents of all the fields in the returned linked list of struc-
    /// tures are undefined with the exception of the fts_name and fts_namelen fields.
    @_alwaysEmitIntoClient
    public static var nameOnly: Self { .init(macroValue: FTS_NAMEONLY) }
  }

  public struct SetOption: RawRepresentable {

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

  public struct Info: RawRepresentable, Equatable {

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

extension Fts.Entry: CustomStringConvertible {
  public var description: String {
    "\(String(describing: Self.self))(ptr: \(ptr), name: \(name), level: \(level)"
  }
}

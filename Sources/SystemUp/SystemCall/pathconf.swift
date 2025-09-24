import CUtility
import SystemPackage
import SystemLibc

public extension SystemCall {
  
  /// get configurable pathname variables
  /// - Parameters:
  ///   - path: the name of a file or directory
  ///   - variable: the system variable to be queried
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func pathconf(_ path: borrowing some CString, variable: PathConfVariable) throws(Errno) -> Int {
    Errno.reset()
    let result = path.withUnsafeCString { path in
      SystemLibc.pathconf(path, variable.rawValue)
    }
    if result == -1,
       let err = Errno.systemCurrentValid {
      throw err
    }
    return result
  }

  /// - Parameters:
  ///   - fd: an open file descriptor
  ///   - variable: the system variable to be queried
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func pathconf(_ fd: FileDescriptor, variable: PathConfVariable) throws(Errno) -> Int {
    Errno.reset()
    let result = SystemLibc.fpathconf(fd.rawValue, variable.rawValue)
    if result == -1,
       let err = Errno.systemCurrentValid {
      throw err
    }
    return result
  }

  struct PathConfVariable: RawRepresentable {

    @_alwaysEmitIntoClient
    private init(rawValue: Int) {
      self.rawValue = Int32(rawValue)
    }

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32
    
    /// The maximum file link count.
    @_alwaysEmitIntoClient
    public static var maxLinkCount: Self { .init(rawValue: _PC_LINK_MAX) }
    /// The maximum number of bytes in terminal canonical input line.
    @_alwaysEmitIntoClient
    public static var maxCanonical: Self { .init(rawValue: _PC_MAX_CANON) }
    /// The  maximum number of bytes for which space is available in a terminal input queue.
    @_alwaysEmitIntoClient
    public static var maxInput: Self { .init(rawValue: _PC_MAX_INPUT) }
    /// The maximum number of bytes in a file name.
    @_alwaysEmitIntoClient
    public static var maxFilenameBytes: Self { .init(rawValue: _PC_NAME_MAX) }
    /// The maximum number of bytes in a pathname.
    @_alwaysEmitIntoClient
    public static var maxPathnameBytes: Self { .init(rawValue: _PC_PATH_MAX) }
    /// The maximum number of bytes which will be written atomically to a pipe.
    @_alwaysEmitIntoClient
    public static var maxPipeBuffer: Self { .init(rawValue: _PC_PIPE_BUF) }
    /// Return 1 if appropriate privileges are required for the chown(2) system call, otherwise 0.
    @_alwaysEmitIntoClient
    public static var chownRestricted: Self { .init(rawValue: _PC_CHOWN_RESTRICTED) }
    /// Return 1 if file names longer than KERN_NAME_MAX are truncated.
    @_alwaysEmitIntoClient
    public static var noTrunc: Self { .init(rawValue: _PC_NO_TRUNC) }
    /// Returns the terminal character disabling value.
    @_alwaysEmitIntoClient
    public static var vdisable: Self { .init(rawValue: _PC_VDISABLE) }
    /// The minimum number of bits needed to represent, as a signed integer value, the maximum size of a regular file allowed in the specified directory. The max file
    /// size is 2^(_PC_FILESIZEBITS - 1).
    @_alwaysEmitIntoClient
    public static var filesizeBits: Self { .init(rawValue: _PC_FILESIZEBITS) }
    #if canImport(Darwin)
    /// Returns the number of bits used to store maximum extended attribute size in bytes.  For example, if the maximum attribute size supported by a file system is
    /// 128K, the value returned will be 18.  However a value 18 can mean that the maximum attribute size can be anywhere from (256KB - 1) to 128KB.  As a special
    /// case, the resource fork can have much larger size, and some file system specific extended attributes can have smaller and preset size; for example, Finder
    /// Info is always 32 bytes.
    @_alwaysEmitIntoClient
    public static var xattrSizeBits: Self { .init(rawValue: _PC_XATTR_SIZE_BITS) }
    /// If a file system supports the reporting of holes (see lseek(2)), pathconf() and fpathconf() return a positive number that represents the minimum hole size
    /// returned in bytes.  The offsets of holes returned will be aligned to this same value.  A special value of 1 is returned if the file system does not specify
    /// the minimum hole size but still reports holes.
    @_alwaysEmitIntoClient
    public static var minHoleSize: Self { .init(rawValue: _PC_MIN_HOLE_SIZE) }
    #endif
  }
}

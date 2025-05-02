import SystemLibc
import SystemPackage
import CUtility
import protocol Foundation.ContiguousBytes

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func listXattrNames(_ path: UnsafePointer<CChar>, options: Xattr.Options, mode: SyscallUtilities.PreAllocateCallMode) -> Result<Int, Errno> {
    #if os(macOS) || os(iOS)
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    #endif
    let buffer = mode.toC
    return SyscallUtilities.valueOrErrno { () -> Int in
      #if os(macOS) || os(iOS)
      return listxattr(path, buffer.baseAddress, buffer.count, options.rawValue)
      #elseif os(Linux)
      if options.contains(.noFollow) {
        return llistxattr(path, buffer.baseAddress, buffer.count)
      } else {
        return listxattr(path, buffer.baseAddress, buffer.count)
      }
      #endif
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func listXattrNames(_ fd: FileDescriptor, options: Xattr.Options, mode: SyscallUtilities.PreAllocateCallMode) -> Result<Int, Errno> {
    let buffer = mode.toC
    return SyscallUtilities.valueOrErrno { () -> Int in
      #if os(macOS) || os(iOS)
      flistxattr(fd.rawValue, buffer.baseAddress, buffer.count, options.rawValue)
      #elseif os(Linux)
      flistxattr(fd.rawValue, buffer.baseAddress, buffer.count)
      #endif
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getXattr(_ path: UnsafePointer<CChar>, attributeName: UnsafePointer<CChar>, position: UInt32 = 0, options: Xattr.Options, mode: SyscallUtilities.PreAllocateCallMode) -> Result<Int, Errno> {
    #if os(macOS) || os(iOS)
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    #endif
    let buffer = mode.toC
    return SyscallUtilities.valueOrErrno { () -> Int in
      #if os(macOS) || os(iOS)
      return getxattr(path, attributeName, buffer.baseAddress!, buffer.count, position, options.rawValue)
      #elseif os(Linux)
      if options.contains(.noFollow) {
        return lgetxattr(path, attributeName, buffer.baseAddress!, buffer.count)
      } else {
        return getxattr(path, attributeName, buffer.baseAddress!, buffer.count)
      }
      #endif
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getXattr(_ fd: FileDescriptor, attributeName: UnsafePointer<CChar>, position: UInt32 = 0, options: Xattr.Options, mode: SyscallUtilities.PreAllocateCallMode) -> Result<Int, Errno> {
    #if os(macOS) || os(iOS)
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    #endif
    let buffer = mode.toC
    return SyscallUtilities.valueOrErrno { () -> Int in
      #if os(macOS) || os(iOS)
      fgetxattr(fd.rawValue, attributeName, buffer.baseAddress!, buffer.count, position, options.rawValue)
      #elseif os(Linux)
      fgetxattr(fd.rawValue, attributeName, buffer.baseAddress!, buffer.count)
      #endif
    }
  }

  /// set xattr value for specific key
  /// - Parameters:
  ///   - value: xattr value
  ///   - key: xattr key
  ///   - path: file path
  ///   - options: noFollow, create and replace are accepted
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func setXattr(_ path: UnsafePointer<CChar>, attributeName: UnsafePointer<CChar>, value: some ContiguousBytes, options: Xattr.Options) -> Result<Void, Errno> {
    assert(options.isSubset(of: [.noFollow, .create, .replace]))
    return value.withUnsafeBytes { buffer in
      SyscallUtilities.voidOrErrno { () -> Int32 in
        #if os(macOS) || os(iOS)
        return setxattr(path, attributeName, buffer.baseAddress, buffer.count, 0, options.rawValue)
        #elseif os(Linux)
        if options.contains(.noFollow) {
          return lsetxattr(path, attributeName, buffer.baseAddress, buffer.count, options.rawValue)
        } else {
          return setxattr(path, attributeName, buffer.baseAddress, buffer.count, options.rawValue)
        }
        #endif
      }
    }
  }

  #if os(macOS) || os(iOS)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func setXattr(_ path: UnsafePointer<CChar>, attributeName: UnsafePointer<CChar>, value: some ContiguousBytes, position: UInt32, options: Xattr.Options) -> Result<Void, Errno> {
    assert(options.isSubset(of: [.noFollow, .create, .replace]))
    return value.withUnsafeBytes { buffer in
      SyscallUtilities.voidOrErrno { () -> Int32 in
        setxattr(path, attributeName, buffer.baseAddress, buffer.count, position, options.rawValue)
      }
    }
  }
  #endif

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func removeXattr(_ path: UnsafePointer<CChar>, attributeName: UnsafePointer<CChar>, options: Xattr.Options) -> Result<Void, Errno> {
    #if os(macOS) || os(iOS)
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    #endif
    return SyscallUtilities.voidOrErrno { () -> Int32 in
      #if os(macOS) || os(iOS)
      return removexattr(path, attributeName, options.rawValue)
      #elseif os(Linux)
      if options.contains(.noFollow) {
        return lremovexattr(path, attributeName)
      } else {
        return removexattr(path, attributeName)
      }
      #endif
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func removeXattr(_ fd: FileDescriptor, attributeName: UnsafePointer<CChar>, options: Xattr.Options) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno { () -> Int32 in
      #if os(macOS) || os(iOS)
      fremovexattr(fd.rawValue, attributeName, options.rawValue)
      #elseif os(Linux)
      fremovexattr(fd.rawValue, attributeName)
      #endif
    }
  }
}

extension Xattr {
  @usableFromInline
  internal static func forEachKeyCString<E: Error>(_ keys: XattrType, _ body: (String, UnsafePointer<CChar>) throws(E) -> Void) throws(E) {
    try toTypedThrows(E.self) {
      try keys.withUnsafeBytes { buffer in
        guard var currentStart = buffer.baseAddress, !buffer.isEmpty else {
          return
        }
        let endAddress = currentStart.advanced(by: buffer.count-1)
        while case let length = strlen(currentStart.assumingMemoryBound(to: CChar.self)),
              currentStart + length <= endAddress {
          let key = String(decoding: UnsafeRawBufferPointer(start: currentStart, count: length), as: UTF8.self)
          try body(key, .init(OpaquePointer(currentStart)))
          currentStart = currentStart + length
          if currentStart == endAddress {
            break
          } else {
            currentStart += 1
          }
        }
        assert(currentStart == endAddress, "has non null-terminated string, just ignored!!")
      }
    }
  }
}

public enum Xattr {

  public typealias XattrType = [UInt8]

  ///
  /// - Parameters:
  ///   - path: file path
  ///   - options: noFollow and showCompression are accepted
  /// - Returns: dictionary
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func listAll(path: UnsafePointer<Int8>, options: Options) throws(Errno) -> [String : XattrType] {
    var result = [String : XattrType]()

    try forEachKeyCString(list(path, options: options)) { key, keyCString throws(Errno) in
      result[key] = try get(path: path, key: keyCString, position: 0, options: options)
    }

    return result
  }

  ///
  /// - Parameters:
  ///   - path: file path
  ///   - options: noFollow and showCompression are accepted
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func allKeys(path: UnsafePointer<Int8>, options: Options) throws(Errno) -> [String] {
    var keys = [String]()
    try forEachKeyCString(list(path, options: options))  { key, _ in keys.append(key) }
    return keys
  }

  ///
  /// - Parameters:
  ///   - path: file path
  ///   - key: specific key
  ///   - options: noFollow and showCompression are accepted
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func getValue(path: UnsafePointer<Int8>, for key: UnsafePointer<Int8>, options: Options) throws(Errno) -> XattrType {
    try get(path: path, key: key, position: 0, options: options)
  }

  /// remove all xattr of the file
  /// - Parameters:
  ///   - path: file path
  ///   - options: noFollow and showCompression are accepted
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func removeAll(path: UnsafePointer<Int8>, options: Options) throws(Errno) {
    try forEachKeyCString(list(path, options: options)) { _, key throws(Errno) in
      try SystemCall.removeXattr(path, attributeName: key, options: options).get()
    }
  }

  /// remove xattr for specific key
  /// - Parameters:
  ///   - path: file path
  ///   - key: xattr key
  ///   - options: noFollow and showCompression are accepted
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func removeValue(path: UnsafePointer<Int8>, for key: UnsafePointer<Int8>, options: Options) throws(Errno) {
    try SystemCall.removeXattr(path, attributeName: key, options: options).get()
  }

  @usableFromInline
  internal static func list(_ path: UnsafePointer<Int8>, options: Options) throws(Errno) -> XattrType {
    let size = try SystemCall.listXattrNames(path, options: options, mode: .getSize).get()
    guard size > 0 else {
      return XattrType()
    }
    return try toTypedThrows(Errno.self) {
      try .init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
        let newSize = try SystemCall.listXattrNames(path, options: options, mode: .getValue(.init(buffer))).get()
        assert(newSize <= size)
        initializedCount = newSize
      }
    }
  }

  @usableFromInline
  internal static func get(path: UnsafePointer<Int8>, key: UnsafePointer<Int8>, position: UInt32, options: Options) throws(Errno) -> XattrType {
    let size = try SystemCall.getXattr(path, attributeName: key, position: position, options: options, mode: .getSize).get()
    guard size > 0 else {
      return XattrType()
    }
    return try toTypedThrows(Errno.self) {
      try .init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
        let newSize = try SystemCall.getXattr(path, attributeName: key, position: position, options: options, mode: .getValue(.init(buffer))).get()
        assert(newSize <= size)
        initializedCount = newSize
      }
    }
  }

}

extension Xattr {
  public struct Options: OptionSet {

    public var rawValue: Int32

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    /// Don't follow symbolic links
    @_alwaysEmitIntoClient
    public static var noFollow: Self {
      #if os(macOS) || os(iOS)
      Self(rawValue: XATTR_NOFOLLOW)
      #else
      Self(rawValue: 1 << 16) /* not standard! */
      #endif
    }

    /// set the value, fail if attr already exists
    @_alwaysEmitIntoClient
    public static var create: Self { Self(rawValue: Int32(XATTR_CREATE)) }

    /// set the value, fail if attr does not exist
    @_alwaysEmitIntoClient
    public static var replace: Self { Self(rawValue: Int32(XATTR_REPLACE)) }

    #if os(macOS) || os(iOS)
    /// option for f/getxattr() and f/listxattr() to expose the HFS Compression extended attributes
    @_alwaysEmitIntoClient
    public static var showCompression: Self { Self(rawValue: XATTR_SHOWCOMPRESSION) }
    #endif

    /*
     currently useless
     /// Set this to bypass authorization checking (eg. if doing auth-related work)
     public static let noSecurity = Self(rawValue: XATTR_NOSECURITY)
     /// Set this to bypass the default extended attribute file (dot-underscore file)
     public static let noDefault = Self(rawValue: XATTR_NODEFAULT)
     */
  }

  #if os(macOS) || os(iOS)
  @_alwaysEmitIntoClient
  public static var maxNameLength: Int32 { XATTR_MAXNAMELEN }

  /* See the ATTR_CMN_FNDRINFO section of getattrlist(2) for details on FinderInfo */
  @_alwaysEmitIntoClient
  public static var finderInfoName: String { XATTR_FINDERINFO_NAME }

  @_alwaysEmitIntoClient
  public static var resourceForkName: String { XATTR_RESOURCEFORK_NAME }
  #endif
}

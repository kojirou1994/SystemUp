#if os(macOS) || os(iOS)
import Darwin
#elseif os(Linux)
import Glibc
import CSystemUp
#endif
import SystemPackage

@discardableResult
private func checkXattrError<T: FixedWidthInteger>(_ body: () -> T) throws -> T {
  let result = body()
  if result == -1 {
    throw Errno.current
  }
  return result
}

extension Xattr.XattrType {
  fileprivate func forEachKeyCString(_ body: (String, UnsafePointer<CChar>) throws -> Void) rethrows {
    try withUnsafeBytes { buffer in
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

public enum Xattr {

  public typealias XattrType = [UInt8]

  ///
  /// - Parameters:
  ///   - path: file path
  ///   - options: noFollow and showCompression are accepted
  /// - Returns: dictionary
  public static func listAll(path: UnsafePointer<Int8>, options: Options) throws -> [String : XattrType] {

    var result = [String : XattrType]()

    try _listxattr(path, options: options)
      .forEachKeyCString { key, keyCString in
        result[key] = try _getxattr(path: path, key: keyCString, position: 0, options: options)
      }

    return result
  }

  ///
  /// - Parameters:
  ///   - path: file path
  ///   - options: noFollow and showCompression are accepted
  public static func allKeys(path: UnsafePointer<Int8>, options: Options) throws -> [String] {
    var keys = [String]()
    try _listxattr(path, options: options)
      .forEachKeyCString { key, _ in keys.append(key) }
    return keys
  }

  ///
  /// - Parameters:
  ///   - path: file path
  ///   - key: specific key
  ///   - options: noFollow and showCompression are accepted
  public static func getValue(path: UnsafePointer<Int8>, for key: UnsafePointer<Int8>, options: Options) throws -> XattrType {
    try _getxattr(path: path, key: key, position: 0, options: options)
  }

  /// set xattr value for specific key
  /// - Parameters:
  ///   - value: xattr value
  ///   - key: xattr key
  ///   - path: file path
  ///   - options: noFollow, create and replace are accepted
  public static func set(_ value: XattrType, for key: UnsafePointer<Int8>, path: UnsafePointer<Int8>, options: Options) throws {
    assert(options.isSubset(of: [.noFollow, .create, .replace]))
    try value.withUnsafeBytes { buffer in
      _ = try checkXattrError { () -> Int32 in
        #if os(macOS) || os(iOS)
        return setxattr(path, key, buffer.baseAddress, buffer.count, 0, options.rawValue)
        #elseif os(Linux)
        if options.contains(.noFollow) {
          return lsetxattr(path, key, buffer.baseAddress, buffer.count, options.rawValue)
        } else {
          return setxattr(path, key, buffer.baseAddress, buffer.count, options.rawValue)
        }
        #endif
      }
    }
  }

  /// remove all xattr of the file
  /// - Parameters:
  ///   - path: file path
  ///   - options: noFollow and showCompression are accepted
  public static func removeAll(path: UnsafePointer<Int8>, options: Options) throws {
    try _listxattr(path, options: options)
      .forEachKeyCString { _, key in
        try _removexattr(path: path, name: key, options: options)
      }
  }

  /// remove xattr for specific key
  /// - Parameters:
  ///   - path: file path
  ///   - key: xattr key
  ///   - options: noFollow and showCompression are accepted
  public static func removeValue(path: UnsafePointer<Int8>, for key: UnsafePointer<Int8>, options: Options) throws {
    try _removexattr(path: path, name: key, options: options)
  }

  private static func _getxattr(path: UnsafePointer<Int8>, key: UnsafePointer<Int8>, position: UInt32, options: Options) throws -> XattrType {
    #if os(macOS) || os(iOS)
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    #endif
    let size = try checkXattrError { () -> Int in
      #if os(macOS) || os(iOS)
      return getxattr(path, key, nil, 0, position, options.rawValue)
      #elseif os(Linux)
      if options.contains(.noFollow) {
        return lgetxattr(path, key, nil, 0)
      } else {
        return getxattr(path, key, nil, 0)
      }
      #endif
    }
    guard size > 0 else {
      return XattrType()
    }
    return try .init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
      let newSize = try checkXattrError { () -> Int in
        #if os(macOS) || os(iOS)
        return getxattr(path, key, buffer.baseAddress!, size, position, options.rawValue)
        #elseif os(Linux)
        if options.contains(.noFollow) {
          return lgetxattr(path, key, buffer.baseAddress!, size)
        } else {
          return getxattr(path, key, buffer.baseAddress!, size)
        }
        #endif
      }
      assert(newSize <= size)
      initializedCount = newSize
    }
  }

  private static func _removexattr(path: UnsafePointer<Int8>, name: UnsafePointer<Int8>, options: Options) throws {
    #if os(macOS) || os(iOS)
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    #endif
    try checkXattrError { () -> Int32 in
      #if os(macOS) || os(iOS)
      return removexattr(path, name, options.rawValue)
      #elseif os(Linux)
      if options.contains(.noFollow) {
        return lremovexattr(path, name)
      } else {
        return removexattr(path, name)
      }
      #endif
    }
  }

  private static func _listxattr(_ path: UnsafePointer<Int8>, options: Options) throws -> XattrType {
    #if os(macOS) || os(iOS)
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    #endif
    let size = try checkXattrError { () -> Int in
      #if os(macOS) || os(iOS)
      return listxattr(path, nil, 0, options.rawValue)
      #elseif os(Linux)
      if options.contains(.noFollow) {
        return llistxattr(path, nil, 0)
      } else {
        return listxattr(path, nil, 0)
      }
      #endif
    }
    guard size > 0 else {
      return XattrType()
    }
    return try .init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
      let newSize = try checkXattrError { () -> Int in
        #if os(macOS) || os(iOS)
        return listxattr(path, buffer.baseAddress, size, options.rawValue)
        #elseif os(Linux)
        if options.contains(.noFollow) {
          return llistxattr(path, buffer.baseAddress, size)
        } else {
          return listxattr(path, buffer.baseAddress, size)
        }
        #endif
      }
      assert(newSize <= size)
      initializedCount = newSize
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

#if canImport(Darwin)
import Darwin
import SystemPackage

@discardableResult
private func checkXattrError<T: FixedWidthInteger>(_ result: T) throws -> T {
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
  public static func listAll(path: String, options: XattrOptions) throws -> [String : XattrType] {
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    return try path.withCString { path in
      var result = [String : XattrType]()

      try _listxattr(path, options: options.rawValue)
        .forEachKeyCString { key, keyCString in
          result[key] = try _getxattr(path: path, key: keyCString, position: 0, options: options.rawValue)
        }
      return result
    }
  }

  ///
  /// - Parameters:
  ///   - path: file path
  ///   - options: noFollow and showCompression are accepted
  public static func allKeys(path: String, options: XattrOptions) throws -> [String] {
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    var keys = [String]()
    try _listxattr(path, options: options.rawValue)
      .forEachKeyCString { key, _ in keys.append(key) }
    return keys
  }

  ///
  /// - Parameters:
  ///   - path: file path
  ///   - key: specific key
  ///   - options: noFollow and showCompression are accepted
  public static func getValue(path: String, for key: String, options: XattrOptions) throws -> XattrType {
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    return try _getxattr(path: path, key: key, position: 0, options: options.rawValue)
  }

  /// set xattr value for specific key
  /// - Parameters:
  ///   - value: xattr value
  ///   - key: xattr key
  ///   - path: file path
  ///   - options: noFollow, create and replace are accepted
  public static func set(_ value: XattrType, for key: String, path: String, options: XattrOptions) throws {
    assert(options.isSubset(of: [.noFollow, .create, .replace]))
    try value.withUnsafeBytes { buffer in
      _ = try checkXattrError(setxattr(path, key, buffer.baseAddress, buffer.count, 0, options.rawValue))
    }
  }

  /// remove all xattr of the file
  /// - Parameters:
  ///   - path: file path
  ///   - options: noFollow and showCompression are accepted
  public static func removeAll(path: String, options: XattrOptions) throws {
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    try path.withCString { path in
      try _listxattr(path, options: options.rawValue)
        .forEachKeyCString { _, key in
          try _removexattr(path: path, name: key, options: options.rawValue)
        }
    }
  }

  /// remove xattr for specific key
  /// - Parameters:
  ///   - path: file path
  ///   - key: xattr key
  ///   - options: noFollow and showCompression are accepted
  public static func removeValue(path: String, for key: String, options: XattrOptions) throws {
    assert(options.isSubset(of: [.noFollow, .showCompression]))
    try _removexattr(path: path, name: key, options: options.rawValue)
  }

  private static func _getxattr(path: UnsafePointer<Int8>, key: UnsafePointer<Int8>, position: UInt32, options: Int32) throws -> XattrType {
    let size = try checkXattrError(getxattr(path, key, nil, 0, position, options))
    guard size > 0 else {
      return XattrType()
    }
    return try .init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
      let newSize = try checkXattrError(getxattr(path, key, buffer.baseAddress!, size, position, options))
      assert(newSize <= size)
      initializedCount = newSize
    }
  }

  private static func _removexattr(path: UnsafePointer<Int8>, name: UnsafePointer<Int8>, options: Int32) throws {
    try checkXattrError(removexattr(path, name, options))
  }

  private static func _listxattr(_ path: UnsafePointer<Int8>, options: Int32) throws -> XattrType {
    let size = try checkXattrError(listxattr(path, nil, 0, options))
    guard size > 0 else {
      return XattrType()
    }
    return try .init(unsafeUninitializedCapacity: size) { buffer, initializedCount in
      let newSize = try checkXattrError(listxattr(path, .init(OpaquePointer(buffer.baseAddress)), size, options))
      assert(newSize <= size)
      initializedCount = newSize
    }
  }

}

extension Xattr {
  public struct XattrOptions: OptionSet {

    public var rawValue: Int32

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    /// Don't follow symbolic links
    @_alwaysEmitIntoClient
    public static var noFollow: Self { Self(rawValue: XATTR_NOFOLLOW) }
    /// set the value, fail if attr already exists
    @_alwaysEmitIntoClient
    public static var create: Self { Self(rawValue: XATTR_CREATE) }
    /// set the value, fail if attr does not exist
    @_alwaysEmitIntoClient
    public static var replace: Self { Self(rawValue: XATTR_REPLACE) }
    /// option for f/getxattr() and f/listxattr() to expose the HFS Compression extended attributes
    @_alwaysEmitIntoClient
    public static var showCompression: Self { Self(rawValue: XATTR_SHOWCOMPRESSION) }
    /*
     currently useless
     /// Set this to bypass authorization checking (eg. if doing auth-related work)
     public static let noSecurity = Self(rawValue: XATTR_NOSECURITY)
     /// Set this to bypass the default extended attribute file (dot-underscore file)
     public static let noDefault = Self(rawValue: XATTR_NODEFAULT)
     */
  }

  @_alwaysEmitIntoClient
  public static var maxNameLength: Int32 { XATTR_MAXNAMELEN }

  /* See the ATTR_CMN_FNDRINFO section of getattrlist(2) for details on FinderInfo */
  @_alwaysEmitIntoClient
  public static var finderInfoName: String { XATTR_FINDERINFO_NAME }

  @_alwaysEmitIntoClient
  public static var resourceForkName: String { XATTR_RESOURCEFORK_NAME }
}
#endif

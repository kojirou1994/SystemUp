import SystemLibc
import SystemPackage
import CUtility

public extension SystemCall {

  struct TemporaryFileInfo: ~Copyable {
    public let fd: FileDescriptor
    public let filename: DynamicCString

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(fd: FileDescriptor, filename: consuming DynamicCString) {
      self.fd = fd
      self.filename = filename
    }
  }

  /// create a unique temporary opened file
  /// - Parameters:
  ///   - template: template string
  ///   - suffixLength:suffix bytes length to be kept
  ///   - options: open options for file
  /// - Returns: file descriptor and generated filename string
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createTemporaryFile(template: borrowing some CString, suffixLength: Int32? = nil, options: FileDescriptor.OpenOptions? = nil) throws(Errno) -> TemporaryFileInfo  {
    var template = DynamicCString.copy(cString: template)
    let fd = try createTemporaryFile(template: &template, suffixLength: suffixLength, options: options)
    return .init(fd: fd, filename: template)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createTemporaryFile(template: inout DynamicCString, suffixLength: Int32? = nil, options: FileDescriptor.OpenOptions? = nil) throws(Errno) -> FileDescriptor {
    try SyscallUtilities.valueOrErrno {
      template.withMutableCString { template in
        switch (suffixLength, options) {
        case (.none, .none):
          SystemLibc.mkstemp(template)
        case let (suffixLength?, options?):
          SystemLibc.mkostemps(template, suffixLength, options.rawValue)
        case let (suffixLength?, .none):
          SystemLibc.mkstemps(template, suffixLength)
        case let (.none, options?):
          SystemLibc.mkostemp(template, options.rawValue)
        }
      }
    }.map(FileDescriptor.init).get()
  }

  @available(*, deprecated)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func mktemp(template: inout DynamicCString) throws(Errno) {
    let result = try SyscallUtilities.unwrap {
      template.withMutableCString { template in
        SystemLibc.mktemp(template)
      }
    }.get()
    template.withUnsafeCString { template in
      assert(result == template)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func mkdtemp(template: inout DynamicCString) throws(Errno) {
    let result = try SyscallUtilities.unwrap {
      template.withMutableCString { template in
        SystemLibc.mkdtemp(template)
      }
    }.get()
    template.withUnsafeCString { template in
      assert(result == template)
    }
  }
}


// MARK: NonPosix

public extension SystemCall {

  #if canImport(Darwin)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createTemporaryFile(template: inout DynamicCString, relativeTo base: RelativeDirectory = .cwd, suffixLength: Int32, options: FileDescriptor.OpenOptions? = nil) throws(Errno) -> FileDescriptor {
    try SyscallUtilities.valueOrErrno {
      template.withMutableCString { template in
        if let options {
          mkostempsat_np(base.toFD, template, suffixLength, options.rawValue)
        } else {
          mkstempsat_np(base.toFD, template, suffixLength)
        }
      }
    }.map(FileDescriptor.init).get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func mkdtemp(template: inout DynamicCString, relativeTo base: RelativeDirectory) throws(Errno) {
    let result = try SyscallUtilities.unwrap {
      template.withMutableCString { template in
        SystemLibc.mkdtempat_np(base.toFD, template)
      }
    }.get()
    template.withUnsafeCString { template in
      assert(result == template)
    }
  }
  #endif
}

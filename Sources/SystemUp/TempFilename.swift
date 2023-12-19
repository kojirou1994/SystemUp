import SystemLibc
import SystemPackage
import CUtility
import CGeneric

public extension SystemCall {
  /// create a unique temporary opened file
  /// - Parameters:
  ///   - template: template string
  ///   - suffixLength:suffix bytes length to be kept
  ///   - options: open options for file
  /// - Returns: file descriptor and generated filename string
  @CStringGeneric()
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createTemporaryFile(template: String, suffixLength: Int32? = nil, options: FileDescriptor.OpenOptions? = nil) -> Result<(FileDescriptor, LazyCopiedCString), Errno> {
    let template = DynamicCString.copy(cString: template)
    switch createTemporaryFile(template: template, suffixLength: suffixLength, options: options) {
    case .success(let fd):
      return .success((fd, LazyCopiedCString(cString: template.take(), freeWhenDone: true)))
    case .failure(let error):
      return .failure(error)
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func createTemporaryFile(template: borrowing DynamicCString, suffixLength: Int32? = nil, options: FileDescriptor.OpenOptions? = nil) -> Result<FileDescriptor, Errno> {
    SyscallUtilities.valueOrErrno {
      template.withMutableCString { template in
        switch (suffixLength, options) {
        case (.none, .none):
          return mkstemp(template)
        case let (suffixLength?, options?):
          return mkostemps(template, suffixLength, options.rawValue)
        case let (suffixLength?, .none):
          return mkstemps(template, suffixLength)
        case let (.none, options?):
          return mkostemp(template, options.rawValue)
        }
      }
    }.map(FileDescriptor.init)
  }
}

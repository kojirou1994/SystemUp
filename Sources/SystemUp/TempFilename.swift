import SystemLibc
import SystemPackage
import CUtility

public enum TempFilename {}

public extension TempFilename {
  /// create a unique temporary opened file
  /// - Parameters:
  ///   - template: template string
  ///   - suffixLength:suffix bytes length to be kept
  ///   - options: open options for file
  /// - Returns: file descriptor and generated filename string
  @inlinable
  static func create(template: some StringProtocol, suffixLength: Int32? = nil, options: FileDescriptor.OpenOptions? = nil) -> Result<(FileDescriptor, LazyCopiedCString), Errno> {
    #if os(Linux)
    assert(template.utf8.dropLast(Int(suffixLength ?? 0)).suffix(6).elementsEqual([UInt8](repeating: .init(ascii: "X"), count: 6)), "")
    #endif
    return SyscallUtilities
      .unwrap { template.withCString(strdup) }
      .flatMap { template in
        switch create(template: template, suffixLength: suffixLength, options: options) {
        case .success(let fd):
          return .success((fd, LazyCopiedCString(cString: template, freeWhenDone: true)))
        case .failure(let error):
          template.deallocate()
          return .failure(error)
        }
      }
  }

  @inlinable @inline(__always)
  static func create(template: UnsafeMutablePointer<CChar>, suffixLength: Int32? = nil, options: FileDescriptor.OpenOptions? = nil) -> Result<FileDescriptor, Errno> {
    SyscallUtilities.valueOrErrno {
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

    }.map(FileDescriptor.init)
  }
}

import SystemPackage

public struct FilePathOption {
  @usableFromInline
  internal init(path: FilePath, relativedDirFD: FileDescriptor) {
    self.path = path
    self.relativedDirFD = relativedDirFD
  }

  public let path: FilePath
  public let relativedDirFD: FileDescriptor
}

public extension FilePathOption {
  @_alwaysEmitIntoClient
  static func absolute(_ path: FilePath) -> Self {
    .init(path: path, relativedDirFD: .currentWorkingDirectory)
  }

  @_alwaysEmitIntoClient
  static func relative(_ path: FilePath, toDirectory fd: FileDescriptor) -> Self {
    .init(path: path, relativedDirFD: fd)
  }
}

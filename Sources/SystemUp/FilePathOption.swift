import SystemPackage

public struct FilePathOption {
  let path: FilePath
  let relativedDirFD: FileDescriptor
}

public extension FilePathOption {
  static func absolute(_ path: FilePath) -> Self {
    .init(path: path, relativedDirFD: .currentWorkingDirectory)
  }

  static func relative(_ path: FilePath, toDirectory fd: FileDescriptor) -> Self {
    .init(path: path, relativedDirFD: fd)
  }
}

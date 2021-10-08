import SystemPackage

extension FilePath {
  public var fileExists: Bool {
    do {
      _ = try FileUtility.fileStatus(self, flags: .noFollow)
      return true
    } catch {
      return false
    }
  }
}

public extension FileUtility {

  @_alwaysEmitIntoClient
  static func createDirectoryIntermediately(_ path: FilePath, permissions: FilePermissions = .directoryDefault) throws {
    do {
      let status = try fileStatus(path)
      if status.fileType == .directory {
        return
      } else {
        throw Errno.fileExists
      }
    } catch Errno.noSuchFileOrDirectory {
      // create parent
      var parent = path
      if parent.removeLastComponent(), !parent.isEmpty {
        try createDirectoryIntermediately(parent, permissions: permissions)
      }
    }
    try createDirectory(path, permissions: permissions)
  }

  @_alwaysEmitIntoClient
  static func remove(_ path: FilePath) throws {
    assert(!path.isEmpty)
    let s = try fileStatus(path, flags: .noFollow)
    if s.fileType == .directory {
      try removeDirectoryRecursive(path)
    } else {
      try unlink(path)
    }
  }

  @_alwaysEmitIntoClient
  static func removeDirectoryRecursive(_ path: FilePath) throws {
    try Directory.open(path)
      .closeAfter { directory in
        var entry = Directory.Entry()
        while try directory.read(into: &entry) {
          if entry.isInvalid {
            continue
          }
          let entryName = entry.name
          let childPath = path.appending(entryName)
          switch entry.fileType {
          case .directory: try removeDirectoryRecursive(childPath)
          default: try unlink(childPath)
          }
        }
      } // Directory open
    try removeDirectory(path)
  }

}

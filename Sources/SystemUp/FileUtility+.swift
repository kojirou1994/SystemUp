import SystemPackage

extension FilePath {
  public var fileExists: Bool {
    do {
      _ = try FileUtility.fileStatus(.absolute(self), flags: .noFollow)
      return true
    } catch {
      return false
    }
  }
}

public extension FileUtility {

  struct DirectoryEnumerationOptions : OptionSet {

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    public let rawValue: Int

    public static var skipsHiddenFiles: Self { .init(rawValue: 1) }

    //    public static var includesDirectoriesPostOrder: FileManager.DirectoryEnumerationOptions { get }

    public static var producesRelativePaths: Self { .init(rawValue: 1 << 1) }
  }

  static func contents(ofDirectory path: FilePath, options: DirectoryEnumerationOptions = []) throws -> [FilePath] {
    try Directory.open(path).closeAfter { directory in
      try contents(ofDirectory: directory, path: path, options: options)
    }
  }

  static func contents(ofDirectory directory: Directory, path: FilePath, options: DirectoryEnumerationOptions = []) throws -> [FilePath] {
    var results = [FilePath]()

    while let nextEntry = try directory.read() {
      if nextEntry.pointee.isInvalid {
        continue
      }
      nextEntry.pointee.withNameBuffer { nameBuffer in
        if options.contains(.skipsHiddenFiles), nameBuffer.first == .init(ascii: ".") {
          return
        }
        let cstr = nameBuffer.baseAddress!.assumingMemoryBound(to: CChar.self)
        if options.contains(.producesRelativePaths) {
          results.append(FilePath(platformString: cstr))
        } else {
          results.append(path.appending(FilePath.Component(platformString: cstr)!))
        }
      }
    }

    return results
  }

  static func createDirectoryIntermediately(_ path: FilePath, permissions: FilePermissions = .directoryDefault) throws {
    do {
      let status = try fileStatus(.absolute(path))
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
    try createDirectory(.absolute(path), permissions: permissions)
  }

  static func remove(_ path: FilePath) throws {
    assert(!path.isEmpty)
    let s = try fileStatus(.absolute(path), flags: .noFollow)
    if s.fileType == .directory {
      try removeDirectoryRecursive(path)
    } else {
      try unlink(.absolute(path))
    }
  }

  static func removeDirectory(_ option: FilePathOption) throws {
    try unlink(option, flags: .removeDir)
  }

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
          default: try unlink(.absolute(childPath))
          }
        }
      } // Directory open
    try removeDirectory(.absolute(path))
  }

  static func move(_ src: FilePath, to dst: FilePath) throws {
    assert(!src.isEmpty)
    assert(!dst.isEmpty)
#if DEBUG
    if dst.fileExists {
      print("warning in \(#function) \(#fileID):\(#line): dst \"\(dst)\" will be removed!")
    }
#endif

    switch _rename(.absolute(src), to: .absolute(dst)) {
    case .success: return
    case .failure(let errno):
      guard errno == .improperLink else {
        throw errno
      }
      // different file system, copy and remove
      try copyFile(from: src, to: dst, flags: [.all, .nofollow, .move, .unlink])
    }
  }

}


public extension FileUtility {
  static func homeDirectoryPath(forUser username: String? = nil) -> FilePath {
    fatalError()
  }
}

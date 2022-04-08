import SystemPackage
import SystemUp

public struct SystemFileManager {}

extension SystemFileManager {

  public static func createDirectoryIntermediately(_ option: FilePathOption, permissions: FilePermissions = .directoryDefault) throws {
    switch FileSyscalls.fileStatus(option) {
    case .success(let status):
      if status.fileType == .directory {
        return
      } else {
        throw Errno.fileExists
      }
    case .failure(let err):
      switch err {
      case .noSuchFileOrDirectory:
        // create parent
        var parent = option.path
        if parent.removeLastComponent(), !parent.isEmpty {
          try createDirectoryIntermediately(.relative(parent, toDirectory: option.relativedDirFD), permissions: permissions)
        }
      default:
        throw err
      }
    }
    try FileSyscalls.createDirectory(option, permissions: permissions).get()
  }

  public static func remove(_ path: FilePath) -> Result<Void, Errno> {
    FileSyscalls.fileStatus(.absolute(path), flags: .noFollow)
      .flatMap { status in
        if status.fileType == .directory {
          return removeDirectoryRecursive(path)
        } else {
          return FileSyscalls.unlink(.absolute(path))
        }
      }
  }

  public static func removeDirectory(_ path: FilePath) -> Result<Void, Errno> {
    FileSyscalls.unlink(.absolute(path), flags: .removeDir)
  }

  public static func removeDirectoryRecursive(_ path: FilePath) -> Result<Void, Errno> {
    switch Directory.open(path) {
    case .failure(let e): return .failure(e)
    case .success(let directory):
      defer { directory.close() }
      rootloop: while true {
        switch directory.read() {
        case .failure(let e): return .failure(e)
        case .success(let entry):
          if let entry = entry {
            if entry.pointee.isInvalid {
              continue rootloop
            }
            let entryName = entry.pointee.name
            let childPath = path.appending(entryName)
            let result: Result<Void, Errno>
            switch entry.pointee.fileType {
            case .directory: result = removeDirectoryRecursive(childPath)
            default: result = FileSyscalls.unlink(.absolute(childPath))
            }
            switch result {
            case .failure(let e): return .failure(e)
            case .success: break
            }
          } else {
            // read finished
            break rootloop
          }
        }
      }
      return removeDirectory(path)
    }
  }

}

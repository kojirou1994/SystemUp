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

}

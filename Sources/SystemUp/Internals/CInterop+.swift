import SystemPackage
import CSystemUp

extension CInterop {
  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  public typealias UpInodeNumber = UInt64
  #elseif os(Linux)
  public typealias UpInodeNumber = ino_t
  #endif
}

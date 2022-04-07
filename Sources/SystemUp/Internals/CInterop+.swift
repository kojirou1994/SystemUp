import SystemPackage
import CSystemUp

extension CInterop {
  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  public typealias UpInodeNumber = UInt64
  #elseif os(Linux)
  public typealias UpInodeNumber = ino_t
  #endif

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  public typealias UpSeekOffset = UInt64
  #elseif os(Linux)
  public typealias UpSeekOffset = off_t
  #endif

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  public typealias UpDev = dev_t
  #elseif os(Linux)
  public typealias UpDev = dev_t
  #endif

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  public typealias UpNumberOfLinks = nlink_t
  #elseif os(Linux)
  public typealias UpNumberOfLinks = nlink_t
  #endif
}

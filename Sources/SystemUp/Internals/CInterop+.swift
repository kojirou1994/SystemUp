import SystemPackage
import CSystemUp

public extension CInterop {
  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  typealias UpInodeNumber = UInt64
  #elseif os(Linux)
  typealias UpInodeNumber = ino_t
  #endif

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  typealias UpSeekOffset = UInt64
  #elseif os(Linux)
  typealias UpSeekOffset = off_t
  #endif

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  typealias UpSize = Int64
  #elseif os(Linux)
  typealias UpSize = off_t
  #endif

  typealias UpBlocksCount = blkcnt_t

  typealias UpBlockSize = blksize_t

  typealias UpDev = dev_t

  typealias UpNumberOfLinks = nlink_t
}

import SystemPackage
import SystemLibc

public extension CInterop {
  #if canImport(Darwin)
  typealias UpInodeNumber = UInt64
  #elseif os(Linux)
  typealias UpInodeNumber = ino_t
  #endif

  #if canImport(Darwin)
  typealias UpSeekOffset = UInt64
  #elseif os(Linux)
  typealias UpSeekOffset = off_t
  #endif

  #if canImport(Darwin)
  typealias UpSize = Int64
  #elseif os(Linux)
  typealias UpSize = off_t
  #endif

  typealias UpBlocksCount = blkcnt_t

  typealias UpBlockSize = blksize_t

  typealias UpDev = dev_t

  typealias UpNumberOfLinks = nlink_t
}

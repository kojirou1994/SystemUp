import SystemLibc
import SystemPackage
import CUtility

public struct DeviceID: RawRepresentable, Hashable {
  public let rawValue: CInterop.UpDev

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.UpDev) {
    self.rawValue = rawValue
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  public init(major: UInt32, minor: UInt32) {
    self.rawValue = swift_makedev(major, minor)
  }
}

public extension DeviceID {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  var major: UInt32 {
    swift_major(rawValue)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  var minor: UInt32 {
    swift_minor(rawValue)
  }

  #if canImport(Darwin)
  /// The devname() function uses a static buffer, which will be overwritten on subsequent calls.
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  func getName(of type: FileStatus.FileType) -> StaticCString? {
    devname(rawValue, type.rawValue)
      .map { StaticCString(cString: $0) }
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  func copyName(of type: FileStatus.FileType, to buffer: UnsafeMutableBufferPointer<CChar>) -> Bool {
    devname_r(rawValue, type.rawValue, buffer.baseAddress, numericCast(buffer.count)) != nil
  }
  #endif
}

extension DeviceID: CustomStringConvertible {
  public var description: String {
    "DeviceID(major: \(major), minor: \(minor))"
  }
}

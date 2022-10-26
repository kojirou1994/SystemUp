import SystemPackage

public extension FilePermissions {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static var directoryDefault: Self { [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute] }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static var fileDefault: Self { [.ownerReadWrite, .groupRead, .otherRead] }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static var executableDefault: Self { [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute] }
}

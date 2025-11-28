
public extension FilePermissions {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var directoryDefault: Self { [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute] }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var fileDefault: Self { [.ownerReadWrite, .groupRead, .otherRead] }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static var executableDefault: Self { [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute] }
}

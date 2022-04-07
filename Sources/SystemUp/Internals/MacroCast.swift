extension RawRepresentable where RawValue: FixedWidthInteger {
  @_alwaysEmitIntoClient
  init<T: FixedWidthInteger>(_ rawValue: T) {
    self.init(rawValue: numericCast(rawValue))!
  }
}

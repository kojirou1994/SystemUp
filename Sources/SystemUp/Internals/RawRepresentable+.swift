extension RawRepresentable {
  var unknownDescription: String {
    "\(String(describing: Self.self))(unknownRawValue: \(rawValue))"
  }
}

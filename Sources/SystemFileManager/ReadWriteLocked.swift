import SystemUp

@propertyWrapper
public final class ReadWriteLocked<Value> {
  private var value: Value
  private var lock: PosixRWLock

  public init(wrappedValue defaultValue: Value) {
    self.value = defaultValue
    self.lock = try! .init()
  }

  deinit {
    lock.destroy()
  }

  public func withWriteLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
    lock.lockWrite()
    defer {
      lock.unlock()
    }
    return try body(&value)
  }

  public var projectedValue: ReadWriteLocked<Value> {
    get {
      self
    }
  }

  public var wrappedValue: Value {
    get {
      lock.lockRead()
      defer {
        lock.unlock()
      }
      return value
    }
    set {
      lock.lockWrite()
      value = newValue
      lock.unlock()
    }
  }

}

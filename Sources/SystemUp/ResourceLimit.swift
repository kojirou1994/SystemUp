import SystemLibc
import CUtility
import SystemPackage

public struct ResourceLimit {
  @usableFromInline
  internal var rawValue: rlimit

  @inlinable
  public init() {
    rawValue = .init()
  }

  #if canImport(Darwin)
  public typealias Limit = UInt64
  #else
  public typealias Limit = UInt
  #endif

  public struct Resource: MacroRawRepresentable {
    public let rawValue: Int32
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }
}

public extension ResourceLimit {

  @inlinable
  @_alwaysEmitIntoClient
  var soft: Limit {
    _read {
      yield rawValue.rlim_cur
    }
    _modify {
      yield &rawValue.rlim_cur
    }
  }

  @inlinable
  @_alwaysEmitIntoClient
  var hard: Limit {
    _read {
      yield rawValue.rlim_max
    }
    _modify {
      yield &rawValue.rlim_max
    }
  }

  @_alwaysEmitIntoClient
  static var infinityLimit: Limit {
    swift_RLIM_INFINITY()
  }

  @inlinable
  @_alwaysEmitIntoClient
  static func set(_ limit: Self, for resource: Resource) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      withUnsafePointer(to: limit) { limit in
        setrlimit(resource.rawValue, limit.pointer(to: \.rawValue)!)
      }
    }
  }

  @inlinable
  @_alwaysEmitIntoClient
  static func get(to limit: inout Self, for resource: Resource) -> Result<Void, Errno> {
    SyscallUtilities.voidOrErrno {
      withUnsafeMutablePointer(to: &limit) { limit in
        getrlimit(resource.rawValue, limit.pointer(to: \.rawValue)!)
      }
    }
  }

  @inlinable
  @_alwaysEmitIntoClient
  static subscript(resource: Resource) -> Self {
    get {
      var result = Self()
      assertNoFailure {
        get(to: &result, for: resource)
      }
      return result
    }
  }
}

public extension ResourceLimit.Resource {
  @_alwaysEmitIntoClient
  static var coreFileSize: Self { .init(macroValue: RLIMIT_CORE) }
  @_alwaysEmitIntoClient
  static var amountCPUTime: Self { .init(macroValue: RLIMIT_CPU) }
  @_alwaysEmitIntoClient
  static var dataSegmentSize: Self { .init(macroValue: RLIMIT_DATA) }
  @_alwaysEmitIntoClient
  static var createdFileSize: Self { .init(macroValue: RLIMIT_FSIZE) }
  @_alwaysEmitIntoClient
  static var memoryLockSize: Self { .init(rawValue: swift_RLIMIT_MEMLOCK()) }
  @_alwaysEmitIntoClient
  static var openedFiles: Self { .init(macroValue: RLIMIT_NOFILE) }
  @_alwaysEmitIntoClient
  static var simultaneousProcesses: Self { .init(rawValue: swift_RLIMIT_NPROC()) }
  @_alwaysEmitIntoClient
  static var residenSetSize: Self { .init(rawValue: swift_RLIMIT_RSS()) }
  @_alwaysEmitIntoClient
  static var stackSegmentSize: Self { .init(macroValue: RLIMIT_STACK) }
}

extension ResourceLimit: CustomStringConvertible {
  @inline(never)
  public var description: String {
    func limitDescription(_ limit: Limit) -> String {
      if limit == Self.infinityLimit {
        return "infinity"
      }
      return limit.description
    }

    return "\(String(describing: Self.self))(soft: \(limitDescription(soft)), hard: \(limitDescription(hard)))"
  }
}

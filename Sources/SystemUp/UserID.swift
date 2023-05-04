import SystemLibc
import SystemPackage

public struct UserID: RawRepresentable {
  public let rawValue: uid_t
  public init(rawValue: uid_t) {
    self.rawValue = rawValue
  }
}

public extension UserID {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static var process: Self {
    get {
      .init(rawValue: SystemLibc.getuid())
    }
    set {
      assertNoFailure {
        SyscallUtilities.valueOrErrno {
          setuid(newValue.rawValue)
        }
      }
    }
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static var effective: Self {
    get {
      .init(rawValue: SystemLibc.geteuid())
    }
    set {
      assertNoFailure {
        SyscallUtilities.valueOrErrno {
          seteuid(newValue.rawValue)
        }
      }
    }
  }
}

public struct GroupProcessID: RawRepresentable {
  public let rawValue: gid_t
  public init(rawValue: gid_t) {
    self.rawValue = rawValue
  }
}

public extension GroupProcessID {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static var process: Self {
    get {
      .init(rawValue: SystemLibc.getgid())
    }
    set {
      assertNoFailure {
        SyscallUtilities.valueOrErrno {
          setgid(newValue.rawValue)
        }
      }
    }
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static var effective: Self {
    get {
      .init(rawValue: SystemLibc.getegid())
    }
    set {
      assertNoFailure {
        SyscallUtilities.valueOrErrno {
          setegid(newValue.rawValue)
        }
      }
    }
  }
}

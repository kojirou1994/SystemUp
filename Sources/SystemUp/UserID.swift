import SystemLibc
import SystemPackage

public struct UserID: RawRepresentable {
  public let rawValue: uid_t
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: uid_t) {
    self.rawValue = rawValue
  }
}

public extension UserID {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
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

  @_alwaysEmitIntoClient @inlinable @inline(__always)
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
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: gid_t) {
    self.rawValue = rawValue
  }
}

public extension GroupProcessID {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
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

  @_alwaysEmitIntoClient @inlinable @inline(__always)
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

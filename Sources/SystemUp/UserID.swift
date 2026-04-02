import SystemLibc

public struct UserID: RawRepresentable, Sendable, BitwiseCopyable {
  public let rawValue: uid_t
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public init(rawValue: uid_t) {
    self.rawValue = rawValue
  }
}

public extension UserID {
  /// the real user ID of the calling process.
  /// The real user ID is that of the user who has invoked the program.
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
  
  /// the effective user ID gives the process additional permissions during execution of “set-user-ID” mode processes
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

public struct GroupProcessID: RawRepresentable, Sendable, BitwiseCopyable {
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

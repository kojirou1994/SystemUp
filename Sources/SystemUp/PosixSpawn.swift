#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import SystemPackage
import CUtility

public enum PosixSpawn {}

public extension PosixSpawn {

  @inlinable
  static func spawn(_ path: UnsafePointer<CChar>, fileActions: FileActions? = nil, attributes: Attributes? = nil, arguments: CStringArray, environment: CStringArray, searchPATH: Bool) -> Result<WaitPID.PID, Errno> {
    spawn(path, fileActions: fileActions, attributes: attributes, argv: arguments.cArray, envp: environment.cArray, searchPATH: searchPATH)
  }

  @inlinable
  static func spawn(_ path: UnsafePointer<CChar>, fileActions: FileActions? = nil, attributes: Attributes? = nil, argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, envp: UnsafePointer<UnsafeMutablePointer<CChar>?>? = nil, searchPATH: Bool) -> Result<WaitPID.PID, Errno> {

    var pid: pid_t = 0
    assert(argv[0] != nil, "At least argv[0] must be present in the array")

    return voidOrErrno {
      withOptionalUnsafePointer(to: fileActions) { (fap: UnsafePointer<FileActions.CType>?) in
        withOptionalUnsafePointer(to: attributes) { (attrp: UnsafePointer<Attributes.CType>?) -> Int32 in
          if searchPATH {
            return posix_spawnp(&pid, path, fap, attrp, argv, envp)
          } else {
            return posix_spawn(&pid, path, fap, attrp, argv, envp)
          }
        }
      }
    }.map { .init(rawValue: pid) }
  }
}

extension PosixSpawn {

  public struct Attributes {

    #if canImport(Darwin)
    public typealias CType = posix_spawnattr_t?
    private var attributes: CType = nil
    #else
    public typealias CType = posix_spawnattr_t
    private var attributes: CType = .init()
    #endif

    public init() throws {
      try reinitialize()
    }

    public mutating func reinitialize() throws {
      #if canImport(Darwin)
      assert(attributes == nil, "destroy first")
      #endif
      try zeroOrErrnoOnReturn {
        posix_spawnattr_init(&attributes)
      }.get()
    }

    public mutating func destroy() {
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawnattr_destroy(&attributes)
        }
      }
    }

    public struct Flags: OptionSet {

      public init(rawValue: Int16) {
        self.rawValue = rawValue
      }

      public var rawValue: Int16
    }
  }

  public struct FileActions {
    #if canImport(Darwin)
    public typealias CType = posix_spawn_file_actions_t?
    private var fileActions: posix_spawn_file_actions_t?
    #else
    public typealias CType = posix_spawn_file_actions_t
    private var fileActions: posix_spawn_file_actions_t = .init()
    #endif

    public init() throws {
      try reinitialize()
    }

    public mutating func reinitialize() throws {
      try zeroOrErrnoOnReturn {
        posix_spawn_file_actions_init(&fileActions)
      }.get()
    }

    public mutating func destroy() {
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawn_file_actions_destroy(&fileActions)
        }
      }
    }

    public mutating func close(fd: FileDescriptor) {
      posix_spawn_file_actions_addclose(&fileActions, fd.rawValue)
    }

    public mutating func open(_ path: UnsafePointer<CChar>, _ mode: FileDescriptor.AccessMode, options: FileDescriptor.OpenOptions = .init(), permissions: FilePermissions? = nil, fd: FileDescriptor) {
      /*
       path is not copied on old platforms:
       https://sourceware.org/git/gitweb.cgi?p=glibc.git;h=89e435f3559c53084498e9baad22172b64429362
       */
      let oFlag = mode.rawValue | options.rawValue
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawn_file_actions_addopen(&fileActions, fd.rawValue, path, oFlag, permissions?.rawValue ?? 0)
        }
      }
    }

    public mutating func dup2(fd: FileDescriptor, newFD: FileDescriptor) {
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawn_file_actions_adddup2(&fileActions, fd.rawValue, newFD.rawValue)
        }
      }
    }

    #if canImport(Darwin)
    public mutating func markInheritance(fd: FileDescriptor) {
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawn_file_actions_addinherit_np(&fileActions, fd.rawValue)
        }
      }
    }
    #endif

    #if os(macOS)
    @available(macOS 10.15, *)
    public mutating func chdir(_ path: FilePath) {
      neverError {
        zeroOrErrnoOnReturn {
          path.withPlatformString { path in
            posix_spawn_file_actions_addchdir_np(&fileActions, path)
          }
        }
      }
    }

    @available(macOS 10.15, *)
    public mutating func chdir(_ fd: FileDescriptor) {
      posix_spawn_file_actions_addfchdir_np(&fileActions, fd.rawValue)
    }
    #endif

  }
}

public extension PosixSpawn.Attributes {
  /// set or get the spawn-sigdefault attribute on a posix_spawnattr_t
  var sigdefault: SignalSet {
    mutating get {
      var result = SignalSet(rawValue: .init())
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawnattr_getsigdefault(&attributes, &result.rawValue)
        }
      }
      return result
    }
    set {
      neverError {
        zeroOrErrnoOnReturn {
          withUnsafePointer(to: newValue.rawValue) { sigset in
            posix_spawnattr_setsigdefault(&attributes, sigset)
          }
        }
      }
    }
  }

  var flags: Flags {
    mutating get {
      var result = Flags(rawValue: 0)
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawnattr_getflags(&attributes, &result.rawValue)
        }
      }
      return result
    }
    set {
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawnattr_setflags(&attributes, newValue.rawValue)
        }
      }
    }
  }

  /// set or get the spawn-sigmask attribute on a posix_spawnattr_t
  var sigmask: SignalSet {
    mutating get {
      var result = SignalSet(rawValue: .init())
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawnattr_getsigmask(&attributes, &result.rawValue)
        }
      }
      return result
    }
    set {
      neverError {
        zeroOrErrnoOnReturn {
          withUnsafePointer(to: newValue.rawValue) { sigset in
            posix_spawnattr_setsigmask(&attributes, sigset)
          }
        }
      }
    }
  }

  var pgroup: pid_t {
    mutating get {
      var result: pid_t = 0
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawnattr_getpgroup(&attributes, &result)
        }
      }
      return result
    }
    set {
      neverError {
        zeroOrErrnoOnReturn {
          posix_spawnattr_setpgroup(&attributes, newValue)
        }
      }
    }
  }

}

#if canImport(Darwin)
// MARK: Darwin-specific extensions below
public extension PosixSpawn.Attributes {
  mutating func get(universalBinaryPreference: UnsafeMutableBufferPointer<cpu_type_t>, count: inout Int) -> Result<Void, Errno> {
    zeroOrErrnoOnReturn {
      posix_spawnattr_getbinpref_np(&attributes, universalBinaryPreference.count, universalBinaryPreference.baseAddress, &count)
    }
  }

  mutating func set(universalBinaryPreference: UnsafeBufferPointer<cpu_type_t>) -> Int {
    var count = 0
    neverError {
      zeroOrErrnoOnReturn {
        posix_spawnattr_setbinpref_np(&attributes, universalBinaryPreference.count, .init(mutating: universalBinaryPreference.baseAddress), &count)
      }
    }
    return count
  }

  @available(macOS 11.0, iOS 14.0, *)
  mutating func get(cpuPreference: UnsafeMutableBufferPointer<cpu_type_t>, subcpuPreference: UnsafeMutablePointer<cpu_subtype_t>, count: inout Int) -> Result<Void, Errno> {
    zeroOrErrnoOnReturn {
      posix_spawnattr_getarchpref_np(&attributes, cpuPreference.count, cpuPreference.baseAddress, subcpuPreference, &count)
    }
  }

  @available(macOS 11.0, iOS 14.0, *)
  mutating func set(cpuPreference: UnsafeBufferPointer<cpu_type_t>, subcpuPreference: UnsafePointer<cpu_subtype_t>) -> Int {
    var count = 0
    neverError {
      zeroOrErrnoOnReturn {
        posix_spawnattr_setarchpref_np(&attributes, cpuPreference.count, .init(mutating: cpuPreference.baseAddress), .init(mutating: subcpuPreference), &count)
      }
    }
    return count
  }

  mutating func set(auditsessionport: mach_port_t) {
    neverError {
      zeroOrErrnoOnReturn {
        posix_spawnattr_setauditsessionport_np(&attributes, auditsessionport)
      }
    }
  }

  mutating func set(specialport: mach_port_t, which: CInt) {
    neverError {
      zeroOrErrnoOnReturn {
        posix_spawnattr_setspecialport_np(&attributes, specialport, which)
      }
    }
  }

  mutating func set(exceptionports new_port: mach_port_t, mask: exception_mask_t, behavior: exception_behavior_t, flavor: thread_state_flavor_t) {
    neverError {
      zeroOrErrnoOnReturn {
        posix_spawnattr_setexceptionports_np(&attributes, mask, new_port, behavior, flavor)
      }
    }
  }
}
#endif // Darwin end


public extension PosixSpawn.Attributes.Flags {

  @_alwaysEmitIntoClient
  static var resetIDs: Self { .init(macroValue: POSIX_SPAWN_RESETIDS) }

  @_alwaysEmitIntoClient
  static var setPGroup: Self { .init(macroValue: POSIX_SPAWN_SETPGROUP) }

  @_alwaysEmitIntoClient
  static var setSigdefault: Self { .init(macroValue: POSIX_SPAWN_SETSIGDEF) }

  @_alwaysEmitIntoClient
  static var setSigmask: Self { .init(macroValue: POSIX_SPAWN_SETSIGMASK) }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient
  static var setExec: Self { .init(macroValue: POSIX_SPAWN_SETEXEC) }

  @_alwaysEmitIntoClient
  static var startSuspended: Self { .init(macroValue: POSIX_SPAWN_START_SUSPENDED) }

  @_alwaysEmitIntoClient
  static var cloExecDefault: Self { .init(macroValue: POSIX_SPAWN_CLOEXEC_DEFAULT) }
  #endif

  #if canImport(Glibc)
  @_alwaysEmitIntoClient
  static var setSchedParam: Self { .init(macroValue: POSIX_SPAWN_SETSCHEDPARAM) }

  @_alwaysEmitIntoClient
  static var setScheduler: Self { .init(macroValue: POSIX_SPAWN_SETSCHEDULER) }
  #endif

}

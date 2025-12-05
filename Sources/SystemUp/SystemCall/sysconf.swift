import CUtility
import SystemLibc
import SyscallValue

public extension SystemCall {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getInteger(systemVariable: SystemVariableInteger) throws(Errno) -> Int {
    try SyscallUtilities.valueOrErrno {
      SystemLibc.sysconf(systemVariable.rawValue)
    }.get()
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getString(systemVariable: SystemVariableString) throws(Errno) -> String {
    try SyscallUtilities.preallocateSyscall { mode throws(Errno) in
      try getString(systemVariable: systemVariable, fixEmptyCString: false, mode: mode)
    }
  }

  /// get string-valued configurable variables
  /// - Parameters:
  ///   - systemVariable: variable name
  ///   - fixEmptyCString: if true and result is empty string, set \0 to buffer[0]
  /// - Returns: the buffer size needed to hold the entire configuration-defined value, including the terminating null byte. if the variable does not have a configuration defined value, 0 is returned.
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func getString(systemVariable: SystemVariableString, fixEmptyCString: Bool, mode: SyscallUtilities.PreAllocateCallMode) throws(Errno) -> Int {
    Errno.reset()
    let buf = mode.toC
    let result = SystemLibc.confstr(systemVariable.rawValue, buf.baseAddress, buf.count)
    assert(result >= 0, "specified by POSIX")
    if result == 0 {
      if let err = Errno.systemCurrentValid {
        // If the call to confstr() is not successful, 0 is returned and errno is set appropriately
        throw err
      } else {
        // if the variable does not have a configuration defined value, 0 is returned and errno is not modified.
        if fixEmptyCString, !buf.isEmpty {
          buf[buf.startIndex] = 0
        }
      }
    }

    return result
  }

  struct SystemVariableInteger: MacroRawRepresentable {
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
    public let rawValue: Int32

    /// The maximum bytes of argument to execve(2).
    @_alwaysEmitIntoClient
    public static var maxArgumentBytes : Self { .init(macroValue: SystemLibc._SC_ARG_MAX) }
    /// The maximum number of simultaneous processes per user id.
    @_alwaysEmitIntoClient
    public static var maxChildProcesses: Self { .init(macroValue: SystemLibc._SC_CHILD_MAX) }
    /// The frequency of the statistics clock in ticks per second.
    @_alwaysEmitIntoClient
    public static var clockFrequency: Self { .init(macroValue: SystemLibc._SC_CLK_TCK) }
    /// The maximum number of elements in the I/O vector used by readv(2), writev(2), recvmsg(2), and sendmsg(2).
    @_alwaysEmitIntoClient
    public static var maxIOVector: Self { .init(macroValue: SystemLibc._SC_IOV_MAX) }
    /// The maximum number of supplemental groups.
    @_alwaysEmitIntoClient
    public static var maxGroups: Self { .init(macroValue: SystemLibc._SC_NGROUPS_MAX) }
    /// The number of processors configured.
    @_alwaysEmitIntoClient
    public static var processors: Self { .init(macroValue: SystemLibc._SC_NPROCESSORS_CONF) }
    /// The number of processors currently online.
    @_alwaysEmitIntoClient
    public static var processorsOnline: Self { .init(macroValue: SystemLibc._SC_NPROCESSORS_ONLN) }
    /// The maximum number of open files per user id.
    @_alwaysEmitIntoClient
    public static var maxOpenFiles: Self { .init(macroValue: SystemLibc._SC_OPEN_MAX) }
    /// The size of a system page in bytes.
    @_alwaysEmitIntoClient
    public static var pageSize: Self { .init(macroValue: SystemLibc._SC_PAGESIZE) }
    /// The minimum maximum number of streams that a process may have open at any one time.
    @_alwaysEmitIntoClient
    public static var maxStreams: Self { .init(macroValue: SystemLibc._SC_STREAM_MAX) }
    /// The minimum maximum number of types supported for the name of a timezone.
    @_alwaysEmitIntoClient
    public static var maxTimeZoneNames: Self { .init(macroValue: SystemLibc._SC_TZNAME_MAX) }
    /// Return 1 if job control is available on this system, otherwise -1.
    @_alwaysEmitIntoClient
    public static var jobControl: Self { .init(macroValue: SystemLibc._SC_JOB_CONTROL) }
    /// Returns 1 if saved set-group and saved set-user ID is available, otherwise -1.
    @_alwaysEmitIntoClient
    public static var savedIDs: Self { .init(macroValue: SystemLibc._SC_SAVED_IDS) }
    /// The version of IEEE Std 1003.1 (“POSIX.1”) with which the system attempts to comply.
    @_alwaysEmitIntoClient
    public static var version: Self { .init(macroValue: SystemLibc._SC_VERSION) }
    /// The maximum ibase/obase values in the bc(1) utility.
    @_alwaysEmitIntoClient
    public static var maxBcBase: Self { .init(macroValue: SystemLibc._SC_BC_BASE_MAX) }
    /// The maximum array size in the bc(1) utility.
    @_alwaysEmitIntoClient
    public static var maxBcArraySize: Self { .init(macroValue: SystemLibc._SC_BC_DIM_MAX) }
    /// The maximum scale value in the bc(1) utility.
    @_alwaysEmitIntoClient
    public static var maxBcScale: Self { .init(macroValue: SystemLibc._SC_BC_SCALE_MAX) }
    /// The maximum string length in the bc(1) utility.
    @_alwaysEmitIntoClient
    public static var maxBcStringLength: Self { .init(macroValue: SystemLibc._SC_BC_STRING_MAX) }
    /// The maximum number of weights that can be assigned to any entry of the LC_COLLATE order keyword in the locale definition file.
    @_alwaysEmitIntoClient
    public static var maxCollWeights: Self { .init(macroValue: SystemLibc._SC_COLL_WEIGHTS_MAX) }
    /// The maximum number of expressions that can be nested within parenthesis by the expr(1) utility.
    @_alwaysEmitIntoClient
    public static var maxNestedExpressions: Self { .init(macroValue: SystemLibc._SC_EXPR_NEST_MAX) }
    /// The maximum length in bytes of a text-processing utility's input line.
    @_alwaysEmitIntoClient
    public static var maxLineBytes: Self { .init(macroValue: SystemLibc._SC_LINE_MAX) }
    /// The maximum number of repeated occurrences of a regular expression permitted when using interval notation.
    @_alwaysEmitIntoClient
    public static var maxRepeatedRE: Self { .init(macroValue: SystemLibc._SC_RE_DUP_MAX) }

    // MARK: POSIX.2

    /// The version of IEEE Std 1003.2 (“POSIX.2”) with which the system attempts to comply.
    @_alwaysEmitIntoClient
    public static var version2: Self { .init(macroValue: SystemLibc._SC_2_VERSION) }
    /// Return 1 if the system's C-language development facilities support the C-Language Bindings Option, otherwise -1.
    @_alwaysEmitIntoClient
    public static var supportsBindings: Self { .init(macroValue: SystemLibc._SC_2_C_BIND) }
    /// Return 1 if the system supports the C-Language Development Utilities Option, otherwise -1.
    @_alwaysEmitIntoClient
    public static var supportsDev: Self { .init(macroValue: SystemLibc._SC_2_C_DEV) }
    /// Return 1 if the system supports at least one terminal type capable of all operations described in IEEE Std 1003.2 (“POSIX.2”), otherwise -1.
    @_alwaysEmitIntoClient
    public static var supportsPosixTerminal: Self { .init(macroValue: SystemLibc._SC_2_CHAR_TERM) }
    /// Return 1 if the system supports the FORTRAN Development Utilities Option, otherwise -1.
    @_alwaysEmitIntoClient
    public static var supportsFortranDev: Self { .init(macroValue: SystemLibc._SC_2_FORT_DEV) }
    /// Return 1 if the system supports the FORTRAN Runtime Utilities Option, otherwise -1.
    @_alwaysEmitIntoClient
    public static var supportsFortranRuntime: Self { .init(macroValue: SystemLibc._SC_2_FORT_RUN) }
    /// Return 1 if the system supports the creation of locales, otherwise -1.
    @_alwaysEmitIntoClient
    public static var supportsLocaleCreation: Self { .init(macroValue: SystemLibc._SC_2_LOCALEDEF) }
    /// Return 1 if the system supports the Software Development Utilities Option, otherwise -1.
    @_alwaysEmitIntoClient
    public static var supportsSoftwareDev: Self { .init(macroValue: SystemLibc._SC_2_SW_DEV) }
    /// Return 1 if the system supports the User Portability Utilities Option, otherwise -1.
    @_alwaysEmitIntoClient
    public static var supportsUserPortability: Self { .init(macroValue: SystemLibc._SC_2_UPE) }

    // MARK: Non Standard

    /// The number of pages of physical memory.
    ///  Note that it is possible that the product of this value and the value of _SC_PAGESIZE will overflow a long in some configurations on a 32bit machine.
    @_alwaysEmitIntoClient
    public static var physicalMemoryPagesNumber: Self { .init(macroValue: SystemLibc._SC_PHYS_PAGES) }

  }

  struct SystemVariableString: MacroRawRepresentable {
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
    public let rawValue: Int32
    
    #if APPLE
    /// Provides the path to a user's folder. The directory will be created if it does not already exist.
    @_alwaysEmitIntoClient
    public static var darwinUserDirectory: Self { .init(macroValue: SystemLibc._CS_DARWIN_USER_DIR) }
    /// Provides the path to a user's temporary items directory.
    @_alwaysEmitIntoClient
    public static var darwinUserTemporaryDirectory: Self { .init(macroValue: SystemLibc._CS_DARWIN_USER_TEMP_DIR) }
    /// Provides the path to the user's cache directory.
    @_alwaysEmitIntoClient
    public static var darwinUserCacheDirectory: Self { .init(macroValue: SystemLibc._CS_DARWIN_USER_CACHE_DIR) }
    #endif

    /// Return a value for the PATH environment variable that finds all the standard utilities.
    @_alwaysEmitIntoClient
    public static var path: Self { .init(macroValue: SystemLibc._CS_PATH) }

    #if canImport(Glibc)
    @_alwaysEmitIntoClient
    public static var gnuLibcVersion : Self { .init(macroValue: SystemLibc._CS_GNU_LIBC_VERSION) }
    @_alwaysEmitIntoClient
    public static var gnuLibpthreadVersion : Self { .init(macroValue: SystemLibc._CS_GNU_LIBPTHREAD_VERSION) }
    #endif
  }
}

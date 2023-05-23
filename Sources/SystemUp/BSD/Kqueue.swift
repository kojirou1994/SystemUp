#if canImport(Darwin)
import Darwin
import SystemPackage
import CUtility

public struct Kqueue {
  @usableFromInline
  internal init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  @usableFromInline
  internal let rawValue: Int32

  @_alwaysEmitIntoClient
  public static func open() -> Result<Self, Errno> {
    SyscallUtilities.valueOrErrno {
      kqueue()
    }.map(Self.init)
  }

  @_alwaysEmitIntoClient
  __consuming public func close() {
    assertNoFailure {
      SyscallUtilities.retryWhileInterrupted {
        FileSyscalls.close(rawValue)
      }
    }
  }

  @_alwaysEmitIntoClient
  public func register(change: __shared Kevent, eventsOutputTo dest: UnsafeMutableBufferPointer<Kevent> = .init(start: nil, count: 0), timeout: UnsafePointer<timespec>? = nil) -> Result<Int, Errno> {
    withUnsafePointer(to: change) { e in
      register(changes: .init(start: e, count: 1), eventsOutputTo: dest, timeout: timeout)
    }
  }

  @_alwaysEmitIntoClient
  public func register(changes: UnsafeBufferPointer<Kevent>, eventsOutputTo dest: UnsafeMutableBufferPointer<Kevent> = .init(start: nil, count: 0), timeout: UnsafePointer<timespec>? = nil) -> Result<Int, Errno> {
    SyscallUtilities.valueOrErrno {
      kevent(
        rawValue,
        UnsafeRawPointer(changes.baseAddress)?.assumingMemoryBound(to: kevent.self),
        numericCast(changes.count),
        UnsafeMutableRawPointer(dest.baseAddress)?.assumingMemoryBound(to: kevent.self),
        numericCast(dest.count),
        timeout
      )
    }.map(Int.init)
  }

  public struct Kevent: RawRepresentable {
    public var rawValue: kevent
    public init(rawValue: kevent) {
      self.rawValue = rawValue
    }

    @inlinable @inline(__always)
    public init(identifier: some FixedWidthInteger, filter: some FixedWidthInteger, flags: some FixedWidthInteger, filterFlags: some FixedWidthInteger, filterData: some FixedWidthInteger, userDataIdentifier: UnsafeMutableRawPointer?) {
      rawValue = .init(ident: numericCast(identifier), filter: numericCast(filter), flags: numericCast(flags), fflags: numericCast(filterFlags), data: numericCast(filterData), udata: userDataIdentifier)
    }

    @inlinable @inline(__always)
    public init(identifier: some FixedWidthInteger, actions: Actions, filter: Filter, filterFlags: Filter.Flags, filterData: some FixedWidthInteger, userDataIdentifier: UnsafeMutableRawPointer?) {
      self.init(identifier: identifier, filter: filter.rawValue, flags: actions.rawValue, filterFlags: filterFlags.rawValue, filterData: filterData, userDataIdentifier: userDataIdentifier)
    }

    @_alwaysEmitIntoClient
    public var filter: Filter {
      _read { yield Filter(rawValue: rawValue.filter) }
    }

    @_alwaysEmitIntoClient
    public var filterFlags: Filter.Flags {
      _read { yield Filter.Flags(rawValue: rawValue.fflags) }
    }
  }

  public struct Kevent64: RawRepresentable {
    public var rawValue: kevent64_s
    public init(rawValue: kevent64_s) {
      self.rawValue = rawValue
    }

    @inlinable @inline(__always)
    public init(identifier: some FixedWidthInteger, filter: some FixedWidthInteger, flags: some FixedWidthInteger, filterFlags: some FixedWidthInteger, filterData: some FixedWidthInteger, userDataIdentifier: some FixedWidthInteger, filterExtension1: some FixedWidthInteger, filterExtension2: some FixedWidthInteger) {
      rawValue = .init(ident: numericCast(identifier), filter: numericCast(filter), flags: numericCast(flags), fflags: numericCast(filterFlags), data: numericCast(filterData), udata: numericCast(userDataIdentifier), ext: (numericCast(filterExtension1), numericCast(filterExtension2)))
    }
  }

  public struct Filter: RawRepresentable {
    public let rawValue: Int16

    public init(rawValue: Int16) {
      self.rawValue = rawValue
    }

    @usableFromInline
    internal init(macroValue: Int32) {
      self.rawValue = numericCast(macroValue)
    }

    public struct Flags: MacroRawRepresentable, OptionSet {
      public var rawValue: UInt32
      public init(rawValue: UInt32) {
        self.rawValue = rawValue
      }
    }

    public struct VnodeFlags: MacroRawRepresentable, OptionSet {
      public var rawValue: UInt32
      public init(rawValue: UInt32) {
        self.rawValue = rawValue
      }
    }
  }

  public struct Actions: MacroRawRepresentable, OptionSet {
    public var rawValue: UInt16
    public init(rawValue: UInt16) {
      self.rawValue = rawValue
    }
  }

}

// MARK: Structured Kevent

public extension Kqueue.Kevent {
  @_alwaysEmitIntoClient
  static func vnode(fd: FileDescriptor, actions: Kqueue.Actions, flags: Kqueue.Filter.VnodeFlags) -> Self {
    .init(identifier: fd.rawValue, actions: actions, filter: .vnode, filterFlags: .init(rawValue: flags.rawValue), filterData: 0, userDataIdentifier: nil)
  }
}

// MARK: Macros

public extension Kqueue.Filter {
  @_alwaysEmitIntoClient
  static var read: Self { .init(macroValue: EVFILT_READ) }

  @_alwaysEmitIntoClient
  static var write: Self { .init(macroValue: EVFILT_WRITE) }

  /// attached to aio requests
  @_alwaysEmitIntoClient
  static var aio: Self { .init(macroValue: EVFILT_AIO) }

  /// attached to vnodes
  @_alwaysEmitIntoClient
  static var vnode: Self { .init(macroValue: EVFILT_VNODE) }

  /// attached to struct proc
  @_alwaysEmitIntoClient
  static var process: Self { .init(macroValue: EVFILT_PROC) }

  /// attached to struct proc
  @_alwaysEmitIntoClient
  static var signal: Self { .init(macroValue: EVFILT_SIGNAL) }

  /// timers
  @_alwaysEmitIntoClient
  static var timer: Self { .init(macroValue: EVFILT_TIMER) }

  /// Mach portsets
  @_alwaysEmitIntoClient
  static var machPort: Self { .init(macroValue: EVFILT_MACHPORT) }

  /// Filesystem events
  @_alwaysEmitIntoClient
  static var fileSystem: Self { .init(macroValue: EVFILT_FS) }

  /// User events
  @_alwaysEmitIntoClient
  static var user: Self { .init(macroValue: EVFILT_USER) }

  /// Virtual memory events
  @_alwaysEmitIntoClient
  static var virtualMemory: Self { .init(macroValue: EVFILT_VM) }

  /// Exception events
  @_alwaysEmitIntoClient
  static var except: Self { .init(macroValue: EVFILT_EXCEPT) }

  @_alwaysEmitIntoClient
  static var syscount: Self { .init(macroValue: EVFILT_SYSCOUNT) }

}

public extension Kqueue.Actions {

  /// Adds the event to the kqueue. Re-adding an existing event will modify the parameters of the original event, and not result in a duplicate entry. Adding an event automatically enables it, unless overridden by the EV_DISABLE flag.
  @_alwaysEmitIntoClient
  static var add: Self { .init(macroValue: EV_ADD) }

  /// Permit kevent,() kevent64() and kevent_qos() to return the event if it is triggered.
  @_alwaysEmitIntoClient
  static var enable: Self { .init(macroValue: EV_ENABLE) }

  /// Disable the event so kevent,() kevent64() and kevent_qos() will not return it. The filter itself is not disabled.
  @_alwaysEmitIntoClient
  static var disable: Self { .init(macroValue: EV_DISABLE) }

  /// Removes the event from the kqueue. Events which are attached to file descriptors are automatically deleted on the last close of the descriptor.
  @_alwaysEmitIntoClient
  static var delete: Self { .init(macroValue: EV_DELETE) }

  /// This flag is useful for making bulk changes to a kqueue without draining any pending events. When passed as input, it forces EV_ERROR to always be returned. When a filter is successfully added, the data field will be zero.
  @_alwaysEmitIntoClient
  static var receipt: Self { .init(macroValue: EV_RECEIPT) }

  /// Causes the event to return only the first occurrence of the filter being triggered. After the user retrieves the event from the kqueue, it is deleted.
  @_alwaysEmitIntoClient
  static var oneshot: Self { .init(macroValue: EV_ONESHOT) }

  /// After the event is retrieved by the user, its state is reset. This is useful for filters which report state transitions instead of the current state. Note that some filters may automatically set this flag internally.
  @_alwaysEmitIntoClient
  static var clear: Self { .init(macroValue: EV_CLEAR) }

  /// Filters may set this flag to indicate filter-specific EOF condition.
  @_alwaysEmitIntoClient
  static var eof: Self { .init(macroValue: EV_EOF) }

  /// Read filter on socket may set this flag to indicate the presence of out of band data on the descriptor.
  @_alwaysEmitIntoClient
  static var ooband: Self { .init(macroValue: EV_OOBAND) }

  @_alwaysEmitIntoClient
  static var error: Self { .init(macroValue: EV_ERROR) }
}

public extension Kqueue.Filter.VnodeFlags {

  /// The unlink() system call was called on the file referenced by the descriptor.
  @_alwaysEmitIntoClient
  static var delete: Self { .init(macroValue: NOTE_DELETE) }

  /// A write occurred on the file referenced by the descriptor.
  @_alwaysEmitIntoClient
  static var write: Self { .init(macroValue: NOTE_WRITE) }

  /// The file referenced by the descriptor was extended.
  @_alwaysEmitIntoClient
  static var extend: Self { .init(macroValue: NOTE_EXTEND) }

  /// The file referenced by the descriptor had its attributes changed.
  @_alwaysEmitIntoClient
  static var attrib: Self { .init(macroValue: NOTE_ATTRIB) }

  /// The link count on the file changed.
  @_alwaysEmitIntoClient
  static var link: Self { .init(macroValue: NOTE_LINK) }

  /// The file referenced by the descriptor was renamed.
  @_alwaysEmitIntoClient
  static var rename: Self { .init(macroValue: NOTE_RENAME) }

  /// Access to the file was revoked via revoke(2) or the underlying fileystem was unmounted.
  @_alwaysEmitIntoClient
  static var revoke: Self { .init(macroValue: NOTE_REVOKE) }

  /// The file was unlocked by calling flock(2) or close(2)
  @_alwaysEmitIntoClient
  static var funlock: Self { .init(macroValue: NOTE_FUNLOCK) }

  /// A lease break to downgrade the lease to read lease is requested on the file referenced by the descriptor.
  @_alwaysEmitIntoClient
  static var leaseDowngrade: Self { .init(macroValue: NOTE_LEASE_DOWNGRADE) }

  /// A lease break to release the lease is requested on the file or directory referenced by the descriptor.
  @_alwaysEmitIntoClient
  static var leaseRelease: Self { .init(macroValue: NOTE_LEASE_RELEASE) }
}

public extension Kqueue.Filter.Flags {

  /// The unlink() system call was called on the file referenced by the descriptor.
  @_alwaysEmitIntoClient
  static var delete: Self { .init(macroValue: NOTE_DELETE) }

  /// A write occurred on the file referenced by the descriptor.
  @_alwaysEmitIntoClient
  static var write: Self { .init(macroValue: NOTE_WRITE) }

  /// The file referenced by the descriptor was extended.
  @_alwaysEmitIntoClient
  static var extend: Self { .init(macroValue: NOTE_EXTEND) }

  /// The file referenced by the descriptor had its attributes changed.
  @_alwaysEmitIntoClient
  static var attrib: Self { .init(macroValue: NOTE_ATTRIB) }

  /// The link count on the file changed.
  @_alwaysEmitIntoClient
  static var link: Self { .init(macroValue: NOTE_LINK) }

  /// The file referenced by the descriptor was renamed.
  @_alwaysEmitIntoClient
  static var rename: Self { .init(macroValue: NOTE_RENAME) }

  /// Access to the file was revoked via revoke(2) or the underlying fileystem was unmounted.
  @_alwaysEmitIntoClient
  static var revoke: Self { .init(macroValue: NOTE_REVOKE) }

  /// The file was unlocked by calling flock(2) or close(2)
  @_alwaysEmitIntoClient
  static var funlock: Self { .init(macroValue: NOTE_FUNLOCK) }

  /// A lease break to downgrade the lease to read lease is requested on the file referenced by the descriptor.
  @_alwaysEmitIntoClient
  static var leaseDowngrade: Self { .init(macroValue: NOTE_LEASE_DOWNGRADE) }

  /// A lease break to release the lease is requested on the file or directory referenced by the descriptor.
  @_alwaysEmitIntoClient
  static var leaseRelease: Self { .init(macroValue: NOTE_LEASE_RELEASE) }
}
#endif

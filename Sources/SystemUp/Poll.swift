import SystemLibc
import CUtility

extension SystemCall {
  public struct PollFD {
    @usableFromInline
    internal var rawValue: pollfd

    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(fd: FileDescriptor, events: Events = []) {
      rawValue = .init(fd: fd.rawValue, events: events.rawValue, revents: 0)
    }

    /// File descriptor to poll.
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var fd: FileDescriptor {
      get { .init(rawValue: rawValue.fd) }
      set { rawValue.fd = newValue.rawValue }
    }

    /// Events to poll for.
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var events: Events {
      get { .init(rawValue: rawValue.events) }
      set { rawValue.events = newValue.rawValue }
    }

    /// Events which may occur or have occurred.
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public var returnedEvents: Events {
      .init(rawValue: rawValue.revents)
    }

    public struct Events: OptionSet, MacroRawRepresentable {
      @_alwaysEmitIntoClient @inlinable @inline(__always)
      public init(rawValue: Int16) {
        self.rawValue = rawValue
      }

      public var rawValue: Int16

      /// An exceptional condition has occurred on the device or socket.  This flag is output only, and ignored if present in the input events bitmask.
      @_alwaysEmitIntoClient
      public static var error: Self { .init(macroValue: POLLERR) }

      /// The device or socket has been disconnected.  This flag is output only, and ignored if present in the input events bitmask.  Note that POLLHUP and POLLOUT are mutually exclusive and should never be present in the revents bitmask at the same time.
      @_alwaysEmitIntoClient
      public static var hup: Self { .init(macroValue: POLLHUP) }
      /// any readable data available
      @_alwaysEmitIntoClient
      public static var `in`: Self { .init(macroValue: POLLIN) }
      @_alwaysEmitIntoClient
      public static var fdNotOpen: Self { .init(macroValue: POLLNVAL) }
      @_alwaysEmitIntoClient
      public static var out: Self { .init(macroValue: POLLOUT) }
      @_alwaysEmitIntoClient
      public static var highPriorityDataRead: Self { .init(macroValue: POLLPRI) }
      @_alwaysEmitIntoClient
      public static var priorityDataRead: Self { .init(macroValue: POLLRDBAND) }
      @_alwaysEmitIntoClient
      public static var normalDataRead: Self { .init(macroValue: POLLRDNORM) }
      @_alwaysEmitIntoClient
      public static var priorityDataWrite: Self { .init(macroValue: POLLWRBAND) }
      @_alwaysEmitIntoClient
      public static var normalDataWrite: Self { .init(macroValue: POLLWRNORM) }
    }
  }

  public struct PollTimeout {
    @_alwaysEmitIntoClient @inlinable @inline(__always)
    public init(milliseconds: Int32) {
      self.milliseconds = milliseconds
    }

    public var milliseconds: Int32

    @_alwaysEmitIntoClient
    public static var indefinite: Self { .init(milliseconds: -1) }
  }

  /// return nil if the time limit expires
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  public static func poll(fds: UnsafeMutableBufferPointer<PollFD>, timeout: PollTimeout) throws(Errno) -> Int32? {
    precondition(MemoryLayout<PollFD>.stride == MemoryLayout<pollfd>.stride)
    let ret = SystemLibc.poll(UnsafeMutableRawPointer(fds.baseAddress)?.assumingMemoryBound(to: pollfd.self), numericCast(fds.count), timeout.milliseconds)
    switch ret {
    case -1: throw .systemCurrent
    case 0: return nil
    default: return ret
    }
  }
}

#if canImport(Darwin) || os(FreeBSD)
public extension SystemCall.PollFD.Events {
  /// file may have been extended
  @_alwaysEmitIntoClient
  static var fileExtended: Self { .init(macroValue: POLLEXTEND) }

  /// file attributes may have changed
  @_alwaysEmitIntoClient
  static var fileAttributesChanges: Self { .init(macroValue: POLLATTRIB) }

  /// (un)link/rename may have happened
  @_alwaysEmitIntoClient
  static var linkHappened: Self { .init(macroValue: POLLNLINK) }

  /// file's contents may have changed
  @_alwaysEmitIntoClient
  static var fileContentsChanged: Self { .init(macroValue: POLLWRITE) }
}
#endif


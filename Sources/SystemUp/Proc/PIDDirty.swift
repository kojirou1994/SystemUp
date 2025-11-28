#if os(macOS)
import SystemLibc

extension Proc {
  public enum Dirty {
    @_alwaysEmitIntoClient
    public static func track(pid: ProcessID, flags: TrackFlags) -> Int32 {
      proc_track_dirty(pid.rawValue, flags.rawValue)
    }

    @_alwaysEmitIntoClient
    public static func set(pid: ProcessID, dirty: Bool) -> Int32 {
      proc_set_dirty(pid.rawValue, dirty)
    }

    @_alwaysEmitIntoClient
    public static func get(pid: ProcessID, flags: inout GetFlags) -> Int32 {
      proc_get_dirty(pid.rawValue, &flags.rawValue)
    }

    @_alwaysEmitIntoClient
    public static func clear(pid: ProcessID, flags: UInt32) -> Int32 {
      proc_clear_dirty(pid.rawValue, flags)
    }
  }
}

extension Proc.Dirty {
  public struct TrackFlags: OptionSet {
    @_alwaysEmitIntoClient
    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    private init(_ rawValue: Int32) {
      self.rawValue = .init(bitPattern: rawValue)
    }

    public var rawValue: UInt32
  }

  public struct GetFlags: OptionSet {
    @_alwaysEmitIntoClient
    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    private init(_ rawValue: Int32) {
      self.rawValue = .init(bitPattern: rawValue)
    }

    public var rawValue: UInt32
  }
}

public extension Proc.Dirty.TrackFlags {
  @_alwaysEmitIntoClient
  static var track: Self { .init(PROC_DIRTY_TRACK) }

  @_alwaysEmitIntoClient
  static var allowIdleExit: Self { .init(PROC_DIRTY_ALLOW_IDLE_EXIT) }

  @_alwaysEmitIntoClient
  static var `defer`: Self { .init(PROC_DIRTY_DEFER) }

  @_alwaysEmitIntoClient
  static var launchInProgress: Self { .init(PROC_DIRTY_LAUNCH_IN_PROGRESS) }

  @_alwaysEmitIntoClient
  static var deferAlways: Self { .init(PROC_DIRTY_DEFER_ALWAYS) }
}

public extension Proc.Dirty.GetFlags {
  @_alwaysEmitIntoClient
  static var tracked: Self { .init(PROC_DIRTY_TRACKED) }

  @_alwaysEmitIntoClient
  static var allowsIdleExit: Self { .init(PROC_DIRTY_ALLOWS_IDLE_EXIT) }

  @_alwaysEmitIntoClient
  static var isDirty: Self { .init(PROC_DIRTY_IS_DIRTY) }

  @_alwaysEmitIntoClient
  static var launchIsInProgress: Self { .init(PROC_DIRTY_LAUNCH_IS_IN_PROGRESS) }

}
#endif

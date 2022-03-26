import CProc
import SystemPackage

public enum PIDDirty { }

public extension PIDDirty {
  @_alwaysEmitIntoClient
  static func track(pid: Int32, flags: TrackFlags) throws -> Int32 {
    proc_track_dirty(pid, flags.rawValue)
  }

  @_alwaysEmitIntoClient
  static func set(pid: Int32, dirty: Bool) throws -> Int32 {
    proc_set_dirty(pid, dirty)
  }

  @_alwaysEmitIntoClient
  static func get(pid: Int32, flags: inout GetFlags) throws -> Int32 {
    proc_get_dirty(pid, &flags.rawValue)
  }

  @_alwaysEmitIntoClient
  static func clear(pid: Int32, flags: UInt32) throws -> Int32 {
    proc_clear_dirty(pid, flags)
  }
}

extension PIDDirty {
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

public extension PIDDirty.TrackFlags {
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

public extension PIDDirty.GetFlags {
  @_alwaysEmitIntoClient
  static var tracked: Self { .init(PROC_DIRTY_TRACKED) }

  @_alwaysEmitIntoClient
  static var allowsIdleExit: Self { .init(PROC_DIRTY_ALLOWS_IDLE_EXIT) }

  @_alwaysEmitIntoClient
  static var isDirty: Self { .init(PROC_DIRTY_IS_DIRTY) }

  @_alwaysEmitIntoClient
  static var launchIsInProgress: Self { .init(PROC_DIRTY_LAUNCH_IS_IN_PROGRESS) }

}

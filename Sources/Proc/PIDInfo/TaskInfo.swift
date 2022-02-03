import CProc
import CUtility

public struct TaskInfo {

  @_alwaysEmitIntoClient
  private var info: proc_taskinfo

  public init() {
    info = .init()
  }

}

public extension TaskInfo {

  /// virtual memory size (bytes)
  @_alwaysEmitIntoClient
  var virtualMemorySize: UInt64 { info.pti_virtual_size }

  /// resident memory size (bytes)
  @_alwaysEmitIntoClient
  var residentMemorySize: UInt64 { info.pti_resident_size }

  @_alwaysEmitIntoClient
  var totalUserTime: UInt64 { info.pti_total_user }

  @_alwaysEmitIntoClient
  var totalSystemTime: UInt64 { info.pti_total_system }

  /// existing threads only
  @_alwaysEmitIntoClient
  var threadsUser: UInt64 { info.pti_threads_user }

  @_alwaysEmitIntoClient
  var threadsSystem: UInt64 { info.pti_threads_system }

  /// default policy for new threads
  @_alwaysEmitIntoClient
  var policy: Int32 { info.pti_policy }

  /// number of page faults
  @_alwaysEmitIntoClient
  var pageFaultsCount: Int32 { info.pti_faults }

  /// number of actual pageins
  @_alwaysEmitIntoClient
  var pageinsCount: Int32 { info.pti_pageins }

  /// number of copy-on-write faults
  @_alwaysEmitIntoClient
  var cowFaultsCount: Int32 { info.pti_cow_faults }

  /// number of messages sent
  @_alwaysEmitIntoClient
  var messagesSentCount: Int32 { info.pti_messages_sent }

  /// number of messages received
  @_alwaysEmitIntoClient
  var messagesReceivedCount: Int32 { info.pti_messages_received }

  /// number of mach system calls
  @_alwaysEmitIntoClient
  var machSyscallsCount: Int32 { info.pti_syscalls_mach }

  /// number of unix system calls
  @_alwaysEmitIntoClient
  var unixSyscallsCount: Int32 { info.pti_syscalls_unix }

  /// number of context switches
  @_alwaysEmitIntoClient
  var contextSwitchesCount: Int32 { info.pti_csw }

  /// number of threads in the task
  @_alwaysEmitIntoClient
  var threadsCount: Int32 { info.pti_threadnum }

  /// number of running threads
  @_alwaysEmitIntoClient
  var runningThreadsCount: Int32 { info.pti_numrunning }

  /// task priority
  @_alwaysEmitIntoClient
  var priority: Int32 { info.pti_priority }

}

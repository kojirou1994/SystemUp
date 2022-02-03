import CProc
import CUtility

public struct TaskInfo {

  private var info: proc_taskinfo

  public init() {
    info = .init()
  }

}

public extension TaskInfo {

  /// virtual memory size (bytes)
  var virtualMemorySize: UInt64 { info.pti_virtual_size }

  /// resident memory size (bytes)
  var residentMemorySize: UInt64 { info.pti_resident_size }

  var totalUserTime: UInt64 { info.pti_total_user }

  var totalSystemTime: UInt64 { info.pti_total_system }

  /// existing threads only
  var threadsUser: UInt64 { info.pti_threads_user }

  var threadsSystem: UInt64 { info.pti_threads_system }

  /// default policy for new threads
  var policy: Int32 { info.pti_policy }

  /// number of page faults
  var pageFaultsCount: Int32 { info.pti_faults }

  /// number of actual pageins
  var pageinsCount: Int32 { info.pti_pageins }

  /// number of copy-on-write faults
  var cowFaultsCount: Int32 { info.pti_cow_faults }

  /// number of messages sent
  var messagesSentCount: Int32 { info.pti_messages_sent }

  /// number of messages received
  var messagesReceivedCount: Int32 { info.pti_messages_received }

  /// number of mach system calls
  var machSyscallsCount: Int32 { info.pti_syscalls_mach }

  /// number of unix system calls
  var unixSyscallsCount: Int32 { info.pti_syscalls_unix }

  /// number of context switches
  var contextSwitchesCount: Int32 { info.pti_csw }

  /// number of threads in the task
  var threadsCount: Int32 { info.pti_threadnum }

  /// number of running threads
  var runningThreadsCount: Int32 { info.pti_numrunning }

  /// task priority
  var priority: Int32 { info.pti_priority }

}

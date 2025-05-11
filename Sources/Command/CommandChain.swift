import SystemPackage
import SystemUp

public struct CommandChain: Sendable {
  /// first process stdin
  public var firstStandardInput: Command.ChildIO

  /// last process stdout
  public var lastStandardOutput: Command.ChildIO = .inherit

  /// every process default stderr, don't use .makePipe
  public var defaultStandardError: Command.ChildIO = .inherit

  struct PipeItem: Sendable {
    /// prepared command, stdin and stdout are not set
    let command: Command
  }

  var items: [PipeItem] = []

  public init(firstStandardInput: Command.ChildIO = .inherit) {
    self.firstStandardInput = firstStandardInput
  }

  public mutating func append(_ newExecutable: consuming Command) {
    items.append(.init(command: newExecutable))
  }

  public struct ChainedProcesses {

    var processes: [Command.ChildProcess]

    public var firstProcess: Command.ChildProcess {
      _read {
        yield processes[0]
      }
      _modify {
        yield &processes[0]
      }
    }

    /// last process's output if makePipe
    public let lastStandardOutput: FileDescriptor?

    public mutating func waitUntilExit() -> [WaitPID.ExitStatus] {
      var result = [WaitPID.ExitStatus]()
      result.reserveCapacity(processes.count)
      for index in processes.indices {
        result.append(try! processes[index].wait())
      }
      return result
    }
  }

  public func launch() throws -> ChainedProcesses {
    precondition(items.count > 1, "no need to pipe")
    let first = items[0]
    let last = items[items.count-1]
    let mid = items.dropFirst().dropLast()

    func addNonLast(_ item: PipeItem, stdin: Command.ChildIO) throws -> (Command.ChildProcess, stdoutRead: FileDescriptor) {
      var command = item.command
      command.stdin = stdin
      command.stdout = .makePipe

      let process = try command.spawn()

      return (process, process.stdout!)
    }

    let (firstProcess, secondStdin) = try addNonLast(first, stdin: firstStandardInput)

    var processes: [Command.ChildProcess] = [firstProcess]
    // TODO: wait/kill processes if error

    var lastPipeReadEnd: FileDescriptor = secondStdin
    for item in mid {
      let (newProcess, newStdin) = try addNonLast(item, stdin: .fd(lastPipeReadEnd))
      try lastPipeReadEnd.close()
      lastPipeReadEnd = newStdin
      processes.append(newProcess)
    }

    var command = last.command

    command.stdin = .fd(lastPipeReadEnd)
    command.stdout = lastStandardOutput

    let lastProcess = try command.spawn()
    try lastPipeReadEnd.close()
    processes.append(lastProcess)

    return .init(processes: processes, lastStandardOutput: lastProcess.stdout)
  }

}

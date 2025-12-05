import SystemUp
import CUtility
import SystemLibc

public struct Command: Sendable {

  public let executable: String

  public init(
    executable: String, arg0: String? = nil, arguments: [String] = .init(),
    stdin: ChildIO? = nil, stdout: ChildIO? = nil, stderr: ChildIO? = nil,
  ) {
    self.executable = executable
    self.arg0 = arg0 ?? executable
    self.arguments = arguments
    self.stdin = stdin
    self.stdout = stdout
    self.stderr = stderr
  }

  public var arg0: String
  public var arguments: [String]

  public enum ChildIO: Sendable {
    case inherit
    case null
    case makePipe
    case fd(FileDescriptor)
  }

  public var stdin: ChildIO?
  public var stdout: ChildIO?
  public var stderr: ChildIO?
  public var defaultIO: ChildIO = .inherit

  // TODO: Implement
  private var uid: UserID?
//  private var gui: guid_t?
  private var groups: GroupProcessID?

  public enum EnvironmentSetting: Sendable {
    case null
    case inherit
    case custom(PosixEnvironment, mergeGlobal: Bool)
  }

  public var cwd: String?
  public var environment: EnvironmentSetting = .inherit

  public var searchPATH: Bool = true

  /// enable to avoid SIGPIPE if stdin is pipe
  public var keepPipeFD: Bool = false

}

extension Command {

  public struct ChildPipes {
    var stdin: Pipe?
    var stdout: Pipe?
    var stderr: Pipe?
    let safeMode: Bool

    public struct Pipe {
      public var local: FileDescriptor
      /// nil if not safe mode
      public var remote: FileDescriptor?
    }

    var remoteClosed = false
    var localClosed = false
    var stdinClosed = false

    func check() {
      precondition(remoteClosed)
      precondition(localClosed)
      precondition(stdinClosed)
    }

    public mutating func closeStdInPipe() {
      try! stdin?.remote?.close()
      try! stdin?.local.close()
      stdin = nil
      stdinClosed = true
    }

    mutating func closeLocal() {
      try? stdout?.local.close()
      try? stderr?.local.close()
      stdout = nil
      stderr = nil
      localClosed = true
    }

    // move ownership of stdout pipe
    public mutating func takeStdOut() -> Pipe? {
      let v = stdout
      stdout = nil
      return v
    }

    // move ownership of stderr pipe
    public mutating func takeStdErr() -> Pipe? {
      let v = stderr
      stderr = nil
      return v
    }

    mutating func closeRemote() {
      if !safeMode {
        try? stdin?.remote?.close()
        stdin?.remote = nil
      }
      try? stdout?.remote?.close()
      try? stderr?.remote?.close()
      stdout?.remote = nil
      stderr?.remote = nil
      remoteClosed = true
    }
  }

  /// spawn a new process
  /// - Parameter body: customize FileActions, default setup will be disabled
  /// - Returns: child process
  public func spawn(
    _ body: ((inout PosixSpawn.FileActions) throws(Errno) -> Void)? = nil,
    attributesHandler: (inout PosixSpawn.Attributes) throws(Errno) -> Void = { $0.resetSignals() },
  ) throws(Errno) -> ChildProcess {
    let env: CStringArray
    switch self.environment {
    case .null:
      env = .init()
    case .inherit:
      env = PosixEnvironment.global.envCArray
    case .custom(var custom, mergeGlobal: let mergeGlobal):
      if mergeGlobal {
        #if !$Embedded
        custom.environment.merge(PosixEnvironment.global.environment) { current, _ in current }
        #else
        for kv in PosixEnvironment.global.environment {
          if custom.environment[kv.key] == nil {
            custom.environment[kv.key] = kv.value
          }
        }
        #endif
      }
      env = custom.envCArray
    }

    var attrs = try PosixSpawn.Attributes()
    defer {
      attrs.destroy()
    }
    var fileActions = try PosixSpawn.FileActions()
    defer {
      fileActions.destroy()
    }

    var pipes = ChildPipes(safeMode: keepPipeFD)

    func setupFD(method: ChildIO?, dst: FileDescriptor, write: Bool, _ pipeOut: UnsafeMutablePointer<ChildPipes.Pipe?>?) throws(Errno) {
      switch (method ?? defaultIO) {
      case .inherit:
        fileActions.dup2(fd: dst, newFD: dst)
      case .null:
        fileActions.open("/dev/null", write ? .writeOnly : .readOnly, fd: dst)
      case .makePipe:
        let (reader, writer) = try SystemCall.pipe()
        let (local, remote) = write ? (reader, writer) : (writer, reader)
        fileActions.dup2(fd: remote, newFD: dst)
        pipeOut?.pointee = .init(local: local, remote: remote)
      case .fd(let fileDescriptor):
        fileActions.dup2(fd: fileDescriptor, newFD: dst)
      }
    }

    if let body = body {
      try body(&fileActions)
    } else {
      try setupFD(method: self.stdin, dst: .standardInput, write: false, &pipes.stdin)
      try setupFD(method: self.stdout, dst: .standardOutput, write: true, &pipes.stdout)
      try setupFD(method: self.stderr, dst: .standardError, write: true, &pipes.stderr)
    }

    var restoreCWD: UnsafeMutablePointer<CChar>?
    if let cwd = self.cwd {
      func backupCWD() throws(Errno) {
        restoreCWD = try SystemCall.getWorkingDirectory().take()
        try SystemCall.changeWorkingDirectory(cwd)
      }
      #if os(macOS)
      if #available(macOS 10.15, *) {
        fileActions.chdir(cwd)
      } else {
        try backupCWD()
      }
      #elseif os(Linux)
      fileActions.chdir(cwd)
      #else
      try backupCWD()
      #endif
    }
    defer {
      if let restoreCWD {
        try! SystemCall.changeWorkingDirectory(restoreCWD)
        Memory.free(restoreCWD)
      }
    }

    #if os(macOS)
    attrs.flags.insert(.closeOnExecDefault)
    #elseif os(Linux)
    fileActions.close(fromMinFD: .init(rawValue: 3))
    #endif
    try attributesHandler(&attrs)

    var args = CStringArray()
    args.append(try! .copy(bytes: arg0))
    args.append(contentsOf: arguments)

    do {
      let pid = try PosixSpawn.spawn(executable, fileActions: fileActions, attributes: attrs, arguments: args, environment: env, searchPATH: searchPATH).get()
      pipes.closeRemote()
      return .init(pid: pid, pipes: pipes)
    } catch {
      pipes.closeRemote()
      pipes.closeLocal()
      pipes.closeStdInPipe()
      pipes.check()
      throw error
    }
  }

  public func output() throws(Errno) -> Output {
    var child = try spawn()
    return try child.waitOutput()
  }

  public func status() throws(Errno) -> WaitPID.ExitStatus {
    var child = try spawn()
    return try child.wait()
  }

  public struct ChildProcess {
    public let pid: ProcessID
    public var pipes: ChildPipes

    /// don't call close() directly, call closeStdInPipe()
    public var stdin: FileDescriptor? {
      pipes.stdin?.local
    }
    /// don't call close() directly, call pipes.takeStdOut()
    public var stdout: FileDescriptor? {
      pipes.stdout?.local
    }
    /// don't call close() directly, call pipes.takeStdErr()
    public var stderr: FileDescriptor? {
      pipes.stderr?.local
    }

#if DEBUG
    var running = true
#endif

    public mutating func closeStdInPipe() {
      pipes.closeStdInPipe()
    }

    /// stdout and stderr will be closed after wait call
    /// - Returns: process exit status
    public mutating func wait() throws(Errno) -> WaitPID.ExitStatus {
#if DEBUG
      assert(running, "process already exited")
#endif
      var status: WaitPID.ExitStatus = Memory.undefined()
      _ = try SyscallUtilities.retryWhileInterrupted { () throws(Errno) in
        try WaitPID.wait(.processID(pid), status: &status)
      }

      pipes.closeLocal()
#if DEBUG
      running = false
#endif

      return status
    }

    public mutating func waitOutput() throws(Errno) -> Output {
      var stdout: [UInt8] = []
      var stderr: [UInt8] = []

      try withUnsafeTemporaryAllocationTyped(byteCount: 4096, alignment: MemoryLayout<Int>.alignment) { buffer throws(Errno) in
        switch (self.stdout, self.stderr) {
        case (let out?, let err?):
          try Command.collectOutput(p1: out, v1: &stdout, p2: err, v2: &stderr, buffer: buffer)
        case (let out?, .none):
          try readAllBlocked(fd: out, dst: &stdout, buffer: buffer)
        case (.none, let err?):
          try readAllBlocked(fd: err, dst: &stderr, buffer: buffer)
        case (.none, .none): break
        }
      }

      return try .init(status: wait(), output: stdout, error: stderr)
    }

  }

  public struct Output: Sendable {
    public let status: WaitPID.ExitStatus
    public let output: [UInt8]
    public let error: [UInt8]

    @inlinable
    public init(status: WaitPID.ExitStatus, output: [UInt8], error: [UInt8]) {
      self.status = status
      self.output = output
      self.error = error
    }

    @inlinable
    public var outputUTF8String: String {
      String(decoding: output, as: UTF8.self)
    }

    @inlinable
    public var errorUTF8String: String {
      String(decoding: error, as: UTF8.self)
    }
  }

}

private func readAllBlocked(fd: FileDescriptor, dst: inout [UInt8], buffer: UnsafeMutableRawBufferPointer) throws(Errno) {
    while case let count = try fd.read(into: buffer),
          count > 0 {
      dst.append(contentsOf: UnsafeRawBufferPointer(rebasing: buffer.prefix(count)))
    }
}

extension Command {

  public static func collectOutput(p1: FileDescriptor, v1: inout [UInt8], p2: FileDescriptor, v2: inout [UInt8], buffer: UnsafeMutableRawBufferPointer) throws(Errno) {
    // Set both pipes into nonblocking mode as we're gonna be reading from both
    // in the `select` loop below, and we wouldn't want one to block the other!
    try Command.set(fd: p1, nonBlocking: true)
    try Command.set(fd: p2, nonBlocking: true)

    var fds: [SystemCall.PollFD] = [
      .init(fd: p1, events: .in),
      .init(fd: p2, events: .in)
    ]

//    let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4096, alignment: MemoryLayout<Int>.alignment)

    /// return true if EOF, false if no data can read
    func readAllNonBlock(fd: FileDescriptor, dst: inout [UInt8]) throws(Errno) -> Bool {
      do {
        while true {
          let count = try fd.read(into: buffer)
          if count > 0 {
            dst.append(contentsOf: UnsafeRawBufferPointer(rebasing: buffer.prefix(count)))
          } else if count == 0 {
            return true
          }
        }
      } catch let err {
        if err == .wouldBlock || err == .resourceTemporarilyUnavailable {
          return false
        } else {
          throw err
        }
      }
    }

    while true {
      // wait for either pipe to become readable using `poll`
      _ = try fds.withUnsafeMutableBufferPointer { fds throws(Errno) in
        try SystemCall.poll(fds: fds, timeout: .indefinite)
      }
      if !fds[0].returnedEvents.isEmpty, try readAllNonBlock(fd: p1, dst: &v1) {
        try Command.set(fd: p2, nonBlocking: false)
        try readAllBlocked(fd: p2, dst: &v2, buffer: buffer)
        return
      }

      if !fds[1].returnedEvents.isEmpty, try readAllNonBlock(fd: p2, dst: &v2) {
        try Command.set(fd: p1, nonBlocking: false)
        try readAllBlocked(fd: p1, dst: &v1, buffer: buffer)
        return
      }
    }

  }
}

extension Command {
  public static func set(fd: FileDescriptor, nonBlocking: Bool) throws(Errno) {
    let previous = try FileControl.statusFlags(for: fd)
    let new: FileControl.FileStatusFlags
    if nonBlocking {
      new = previous.union(.nonBlocking)
    } else {
      new = previous.subtracting(.nonBlocking)
    }
    if previous != new {
      try FileControl.set(fd, statusFlags: new)
    }
  }
}

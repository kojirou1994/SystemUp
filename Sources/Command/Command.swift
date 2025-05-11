import SystemPackage
import SystemUp
import CUtility
import SystemLibc

public struct Command {

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

  public enum ChildIO {
    case inherit
    case null
    case makePipe
    case fd(FileDescriptor)
    case path(FilePath, mode: FileDescriptor.AccessMode, options: FileDescriptor.OpenOptions)
  }

  public var stdin: ChildIO?
  public var stdout: ChildIO?
  public var stderr: ChildIO?
  public var defaultIO: ChildIO = .inherit

  // TODO: Implement
  private var uid: UserID?
//  private var gui: guid_t?
  private var groups: GroupProcessID?

  public enum EnvironmentSetting {
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
  public func spawn(_ body: ((inout PosixSpawn.FileActions) throws -> Void)? = nil) throws -> ChildProcess {
    let env: CStringArray
    switch self.environment {
    case .null:
      env = .init()
    case .inherit:
      env = PosixEnvironment.global.envCArray
    case .custom(var custom, mergeGlobal: let mergeGlobal):
      if mergeGlobal {
        custom.environment.merge(PosixEnvironment.global.environment) { current, _ in current }
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

    func setupFD(method: ChildIO?, dst: FileDescriptor, write: Bool, _ keyPath: WritableKeyPath<ChildPipes, ChildPipes.Pipe?>) throws {
      switch (method ?? defaultIO) {
      case .inherit:
        fileActions.dup2(fd: dst, newFD: dst)
      case let .path(path, mode: mode, options: options):
        fileActions.open(path, mode, options: options, permissions: .fileDefault, fd: dst)
      case .null:
        fileActions.open("/dev/null", write ? .writeOnly : .readOnly, fd: dst)
      case .makePipe:
        let (reader, writer) = try FileDescriptor.pipe()
        let (local, remote) = write ? (reader, writer) : (writer, reader)
        fileActions.dup2(fd: remote, newFD: dst)
        pipes[keyPath: keyPath] = .init(local: local, remote: remote)
      case .fd(let fileDescriptor):
        fileActions.dup2(fd: fileDescriptor, newFD: dst)
      }
    }

    if let body = body {
      try body(&fileActions)
    } else {
      try setupFD(method: self.stdin, dst: .standardInput, write: false, \.stdin)
      try setupFD(method: self.stdout, dst: .standardOutput, write: true, \.stdout)
      try setupFD(method: self.stderr, dst: .standardError, write: true, \.stderr)
    }

    var restoreCWD: FilePath?
    if let cwd = self.cwd {
      func backupCWD() throws {
        restoreCWD = try SystemCall.getWorkingDirectory()
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
        try! restoreCWD.withUnsafeCString(SystemCall.changeWorkingDirectory)
      }
    }

    #if os(macOS)
    attrs.flags.insert(.closeOnExecDefault)
    #elseif os(Linux)
    fileActions.close(fromMinFD: .init(rawValue: 3))
    #endif
    attrs.resetSignals()

    var args = CStringArray()
    args.append(.copy(bytes: arg0))
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

  public func output() throws -> Output {
    var child = try spawn()
    return try child.waitOutput()
  }

  public func status() throws -> WaitPID.ExitStatus {
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
    public mutating func wait() throws -> WaitPID.ExitStatus {
#if DEBUG
      assert(running, "process already exited")
#endif
      var status = WaitPID.ExitStatus(rawValue: 0)
      _ = try SyscallUtilities.retryWhileInterrupted {
        WaitPID.wait(.processID(pid), status: &status)
      }.get()

      pipes.closeLocal()
#if DEBUG
      running = false
#endif

      return status
    }

    public mutating func waitOutput() throws -> Output {
      var stdout: [UInt8] = []
      nonisolated(unsafe) var stderr: [UInt8] = []

      switch (self.stdout, self.stderr) {
      case (let out?, let err?):
        nonisolated(unsafe) var errError: Error?
        let errThread = try PosixThread.create {
          do {
            try readAll(fd: err, dst: &stderr)
          } catch {
            print("error output thread error: \(error)")
            errError = error
          }
        }
        do {
          try readAll(fd: out, dst: &stdout)
        } catch {
          errThread.cancel()
          errThread.detach()
          throw error
        }
        _ = try errThread.join().get()
        if let errError {
          throw errError
        }
      case (let out?, .none):
        try readAll(fd: out, dst: &stdout)
      case (.none, let err?):
        try readAll(fd: err, dst: &stderr)
      case (.none, .none): break
      }

      return try .init(status: wait(), output: stdout, error: stderr)
    }

  }

  public struct Output {
    public let status: WaitPID.ExitStatus
    public let output: [UInt8]
    public let error: [UInt8]

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

private func readAll(fd: FileDescriptor, dst: inout [UInt8]) throws {
  var buffer = [UInt8](repeating: 0, count: 4096)
  try buffer.withUnsafeMutableBytes { buffer in
    while case let count = try fd.read(into: buffer),
          count > 0 {
      dst.append(contentsOf: UnsafeRawBufferPointer(rebasing: buffer.prefix(count)))
    }
  }
}


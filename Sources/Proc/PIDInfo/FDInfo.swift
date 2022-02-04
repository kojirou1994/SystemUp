import CProc
import Darwin
import SystemPackage

public struct FDInfo {

  @_alwaysEmitIntoClient
  private var info: proc_fdinfo

  public init() {
    info = .init()
  }

}

public extension FDInfo {

  @_alwaysEmitIntoClient
  var fd: FileDescriptor { .init(rawValue: info.proc_fd) }

  @_alwaysEmitIntoClient
  var fdtype: FDType {
    .init(rawValue: info.proc_fdtype)
  }

}

extension FDInfo: CustomStringConvertible {
  public var description: String {
    "FDInfo(fd: \(info.proc_fd), type: \(fdtype))"
  }
}

extension FDInfo {
  public struct FDType: RawRepresentable {
    @_alwaysEmitIntoClient
    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    private init(_ rawValue: Int32) {
      self.rawValue = .init(bitPattern: rawValue)
    }

    public let rawValue: UInt32
  }
}

public extension FDInfo.FDType {
  @_alwaysEmitIntoClient
  static var atalk: Self { .init(PROX_FDTYPE_ATALK) }

  @_alwaysEmitIntoClient
  static var vnode: Self { .init(PROX_FDTYPE_VNODE) }

  @_alwaysEmitIntoClient
  static var socket: Self { .init(PROX_FDTYPE_SOCKET) }

  @_alwaysEmitIntoClient
  static var pshm: Self { .init(PROX_FDTYPE_PSHM) }

  @_alwaysEmitIntoClient
  static var psem: Self { .init(PROX_FDTYPE_PSEM) }

  @_alwaysEmitIntoClient
  static var kqueue: Self { .init(PROX_FDTYPE_KQUEUE) }

  @_alwaysEmitIntoClient
  static var pipe: Self { .init(PROX_FDTYPE_PIPE) }

  @_alwaysEmitIntoClient
  static var fsEvents: Self { .init(PROX_FDTYPE_FSEVENTS) }

  @_alwaysEmitIntoClient
  static var netPolicy: Self { .init(PROX_FDTYPE_NETPOLICY) }
}

extension FDInfo.FDType: Equatable {}

extension FDInfo.FDType: CustomStringConvertible {
  public var description: String {
    switch self {
    case .atalk: return "atalk"
    case .vnode: return "vnode"
    case .socket: return "socket"
    case .pshm: return "pshm"
    case .psem: return "psem"
    case .kqueue: return "kqueue"
    case .pipe: return "pipe"
    case .fsEvents: return "fsEvents"
    case .netPolicy: return "netPolicy"
    default: return "unknown(\(rawValue))"
    }
  }
}

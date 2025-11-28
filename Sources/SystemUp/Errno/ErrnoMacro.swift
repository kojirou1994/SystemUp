import SystemLibc

public extension Errno {

  @_alwaysEmitIntoClient
  static var notPermitted: Errno { .init(rawValue: EPERM) }
  @_alwaysEmitIntoClient
  static var noSuchFileOrDirectory: Errno { .init(rawValue: ENOENT) }
  @_alwaysEmitIntoClient
  static var noSuchProcess: Errno { .init(rawValue: ESRCH) }
  @_alwaysEmitIntoClient
  static var interrupted: Errno { .init(rawValue: EINTR) }
  @_alwaysEmitIntoClient
  static var ioError: Errno { .init(rawValue: EIO) }
  @_alwaysEmitIntoClient
  static var noSuchAddressOrDevice: Errno { .init(rawValue: ENXIO) }
  @_alwaysEmitIntoClient
  static var argListTooLong: Errno { .init(rawValue: E2BIG) }
  @_alwaysEmitIntoClient
  static var execFormatError: Errno { .init(rawValue: ENOEXEC) }
  @_alwaysEmitIntoClient
  static var badFileDescriptor: Errno { .init(rawValue: EBADF) }
  @_alwaysEmitIntoClient
  static var noChildProcess: Errno { .init(rawValue: ECHILD) }
  @_alwaysEmitIntoClient
  static var deadlock: Errno { .init(rawValue: EDEADLK) }
  @_alwaysEmitIntoClient
  static var noMemory: Errno { .init(rawValue: ENOMEM) }
  @_alwaysEmitIntoClient
  static var permissionDenied: Errno { .init(rawValue: EACCES) }
  @_alwaysEmitIntoClient
  static var badAddress: Errno { .init(rawValue: EFAULT) }
#if !os(Windows) && !os(WASI)
  @_alwaysEmitIntoClient
  static var notBlockDevice: Errno { .init(rawValue: ENOTBLK) }
#endif
  @_alwaysEmitIntoClient
  static var resourceBusy: Errno { .init(rawValue: EBUSY) }
  @_alwaysEmitIntoClient
  static var fileExists: Errno { .init(rawValue: EEXIST) }
  @_alwaysEmitIntoClient
  static var improperLink: Errno { .init(rawValue: EXDEV) }
  @_alwaysEmitIntoClient
  static var operationNotSupportedByDevice: Errno { .init(rawValue: ENODEV) }
  @_alwaysEmitIntoClient
  static var notDirectory: Errno { .init(rawValue: ENOTDIR) }
  @_alwaysEmitIntoClient
  static var isDirectory: Errno { .init(rawValue: EISDIR) }
  @_alwaysEmitIntoClient
  static var invalidArgument: Errno { .init(rawValue: EINVAL) }
  @_alwaysEmitIntoClient
  static var tooManyOpenFilesInSystem: Errno { .init(rawValue: ENFILE) }
  @_alwaysEmitIntoClient
  static var tooManyOpenFiles: Errno { .init(rawValue: EMFILE) }
#if !os(Windows)
  @_alwaysEmitIntoClient
  static var inappropriateIOCTLForDevice: Errno { .init(rawValue: ENOTTY) }
  @_alwaysEmitIntoClient
  static var textFileBusy: Errno { .init(rawValue: ETXTBSY) }
#endif
  @_alwaysEmitIntoClient
  static var fileTooLarge: Errno { .init(rawValue: EFBIG) }
  @_alwaysEmitIntoClient
  static var noSpace: Errno { .init(rawValue: ENOSPC) }
  @_alwaysEmitIntoClient
  static var illegalSeek: Errno { .init(rawValue: ESPIPE) }
  @_alwaysEmitIntoClient
  static var readOnlyFileSystem: Errno { .init(rawValue: EROFS) }
  @_alwaysEmitIntoClient
  static var tooManyLinks: Errno { .init(rawValue: EMLINK) }
  @_alwaysEmitIntoClient
  static var brokenPipe: Errno { .init(rawValue: EPIPE) }
  @_alwaysEmitIntoClient
  static var outOfDomain: Errno { .init(rawValue: EDOM) }
  @_alwaysEmitIntoClient
  static var outOfRange: Errno { .init(rawValue: ERANGE) }
  @_alwaysEmitIntoClient
  static var resourceTemporarilyUnavailable: Errno { .init(rawValue: EAGAIN) }
  @_alwaysEmitIntoClient
  static var nowInProgress: Errno { .init(rawValue: EINPROGRESS) }
  @_alwaysEmitIntoClient
  static var alreadyInProcess: Errno { .init(rawValue: EALREADY) }
  @_alwaysEmitIntoClient
  static var notSocket: Errno { .init(rawValue: ENOTSOCK) }
  @_alwaysEmitIntoClient
  static var addressRequired: Errno { .init(rawValue: EDESTADDRREQ) }
  @_alwaysEmitIntoClient
  static var messageTooLong: Errno { .init(rawValue: EMSGSIZE) }
  @_alwaysEmitIntoClient
  static var protocolWrongTypeForSocket: Errno { .init(rawValue: EPROTOTYPE) }
  @_alwaysEmitIntoClient
  static var protocolNotAvailable: Errno { .init(rawValue: ENOPROTOOPT) }
  @_alwaysEmitIntoClient
  static var protocolNotSupported: Errno { .init(rawValue: EPROTONOSUPPORT) }
#if !os(WASI)
  @_alwaysEmitIntoClient
  static var socketTypeNotSupported: Errno { .init(rawValue: ESOCKTNOSUPPORT) }
#endif
  @_alwaysEmitIntoClient
  static var notSupported: Errno { .init(rawValue: ENOTSUP) }
#if !os(WASI)
  @_alwaysEmitIntoClient
  static var protocolFamilyNotSupported: Errno { .init(rawValue: EPFNOSUPPORT) }
#endif
  @_alwaysEmitIntoClient
  static var addressFamilyNotSupported: Errno { .init(rawValue: EAFNOSUPPORT) }
  @_alwaysEmitIntoClient
  static var addressInUse: Errno { .init(rawValue: EADDRINUSE) }
  @_alwaysEmitIntoClient
  static var addressNotAvailable: Errno { .init(rawValue: EADDRNOTAVAIL) }
  @_alwaysEmitIntoClient
  static var networkDown: Errno { .init(rawValue: ENETDOWN) }
  @_alwaysEmitIntoClient
  static var networkUnreachable: Errno { .init(rawValue: ENETUNREACH) }
  @_alwaysEmitIntoClient
  static var networkReset: Errno { .init(rawValue: ENETRESET) }
  @_alwaysEmitIntoClient
  static var connectionAbort: Errno { .init(rawValue: ECONNABORTED) }
  @_alwaysEmitIntoClient
  static var connectionReset: Errno { .init(rawValue: ECONNRESET) }
  @_alwaysEmitIntoClient
  static var noBufferSpace: Errno { .init(rawValue: ENOBUFS) }
  @_alwaysEmitIntoClient
  static var socketIsConnected: Errno { .init(rawValue: EISCONN) }
  @_alwaysEmitIntoClient
  static var socketNotConnected: Errno { .init(rawValue: ENOTCONN) }
#if !os(WASI)
  @_alwaysEmitIntoClient
  static var socketShutdown: Errno { .init(rawValue: ESHUTDOWN) }
#endif
  @_alwaysEmitIntoClient
  static var timedOut: Errno { .init(rawValue: ETIMEDOUT) }
  @_alwaysEmitIntoClient
  static var connectionRefused: Errno { .init(rawValue: ECONNREFUSED) }
  @_alwaysEmitIntoClient
  static var tooManySymbolicLinkLevels: Errno { .init(rawValue: ELOOP) }
  @_alwaysEmitIntoClient
  static var fileNameTooLong: Errno { .init(rawValue: ENAMETOOLONG) }
#if !os(WASI)
  @_alwaysEmitIntoClient
  static var hostIsDown: Errno { .init(rawValue: EHOSTDOWN) }
#endif
  @_alwaysEmitIntoClient
  static var noRouteToHost: Errno { .init(rawValue: EHOSTUNREACH) }
  @_alwaysEmitIntoClient
  static var directoryNotEmpty: Errno { .init(rawValue: ENOTEMPTY) }
#if SYSTEM_PACKAGE_DARWIN
  @_alwaysEmitIntoClient
  public static var tooManyProcesses: Errno { .init(rawValue: EPROCLIM) }
#endif
#if !os(WASI)
  @_alwaysEmitIntoClient
  static var tooManyUsers: Errno { .init(rawValue: EUSERS) }
#endif
  @_alwaysEmitIntoClient
  static var diskQuotaExceeded: Errno { .init(rawValue: EDQUOT) }
  @_alwaysEmitIntoClient
  static var staleNFSFileHandle: Errno { .init(rawValue: ESTALE) }
  // TODO: Add Linux's RPC equivalents
#if SYSTEM_PACKAGE_DARWIN
  @_alwaysEmitIntoClient
  public static var rpcUnsuccessful: Errno { .init(rawValue: EBADRPC) }
  @_alwaysEmitIntoClient
  public static var rpcVersionMismatch: Errno { .init(rawValue: ERPCMISMATCH) }
  @_alwaysEmitIntoClient
  public static var rpcProgramUnavailable: Errno { .init(rawValue: EPROGUNAVAIL) }
  @_alwaysEmitIntoClient
  public static var rpcProgramVersionMismatch: Errno { .init(rawValue: EPROGMISMATCH) }
  @_alwaysEmitIntoClient
  public static var rpcProcedureUnavailable: Errno { .init(rawValue: EPROCUNAVAIL) }
#endif
  @_alwaysEmitIntoClient
  static var noLocks: Errno { .init(rawValue: ENOLCK) }
  @_alwaysEmitIntoClient
  static var noFunction: Errno { .init(rawValue: ENOSYS) }
  // BSD
#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  @_alwaysEmitIntoClient
  public static var badFileTypeOrFormat: Errno { .init(rawValue: EFTYPE) }
#endif
#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  @_alwaysEmitIntoClient
  public static var authenticationError: Errno { .init(rawValue: EAUTH) }
  @_alwaysEmitIntoClient
  public static var needAuthenticator: Errno { .init(rawValue: ENEEDAUTH) }
#endif
#if SYSTEM_PACKAGE_DARWIN
  @_alwaysEmitIntoClient
  public static var devicePowerIsOff: Errno { .init(rawValue: EPWROFF) }
  @_alwaysEmitIntoClient
  public static var deviceError: Errno { .init(rawValue: EDEVERR) }
#endif
#if !os(Windows)
  @_alwaysEmitIntoClient
  static var overflow: Errno { .init(rawValue: EOVERFLOW) }
#endif
#if SYSTEM_PACKAGE_DARWIN
  @_alwaysEmitIntoClient
  public static var badExecutable: Errno { .init(rawValue: EBADEXEC) }
  @_alwaysEmitIntoClient
  public static var badCPUType: Errno { .init(rawValue: EBADARCH) }
  @_alwaysEmitIntoClient
  public static var sharedLibraryVersionMismatch: Errno { .init(rawValue: ESHLIBVERS) }
  @_alwaysEmitIntoClient
  public static var malformedMachO: Errno { .init(rawValue: EBADMACHO) }
#endif
  @_alwaysEmitIntoClient
  static var canceled: Errno { .init(rawValue: ECANCELED) }
#if !os(Windows)
  @_alwaysEmitIntoClient
  static var identifierRemoved: Errno { .init(rawValue: EIDRM) }
  @_alwaysEmitIntoClient
  static var noMessage: Errno { .init(rawValue: ENOMSG) }
#endif
  @_alwaysEmitIntoClient
  static var illegalByteSequence: Errno { .init(rawValue: EILSEQ) }
#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  @_alwaysEmitIntoClient
  public static var attributeNotFound: Errno { .init(rawValue: ENOATTR) }
#endif
#if !os(Windows)
  @_alwaysEmitIntoClient
  static var badMessage: Errno { .init(rawValue: EBADMSG) }
#if !os(OpenBSD)
  @_alwaysEmitIntoClient
  static var multiHop: Errno { .init(rawValue: EMULTIHOP) }
#if !os(WASI) && !os(FreeBSD)
  @_alwaysEmitIntoClient
  static var noData: Errno { .init(rawValue: ENODATA) }
#endif
  @_alwaysEmitIntoClient
  static var noLink: Errno { .init(rawValue: ENOLINK) }
#if !os(WASI) && !os(FreeBSD)
  @_alwaysEmitIntoClient
  static var noStreamResources: Errno { .init(rawValue: ENOSR) }
  @_alwaysEmitIntoClient
  static var notStream: Errno { .init(rawValue: ENOSTR) }
#endif
#endif
  @_alwaysEmitIntoClient
  static var protocolError: Errno { .init(rawValue: EPROTO) }
#if !os(OpenBSD) && !os(WASI) && !os(FreeBSD)
  @_alwaysEmitIntoClient
  static var timeout: Errno { .init(rawValue: ETIME) }
#endif
#endif
  @_alwaysEmitIntoClient
  static var notSupportedOnSocket: Errno { .init(rawValue: EOPNOTSUPP) }
}
// Constants defined in header but not man page
extension Errno {
  @_alwaysEmitIntoClient
  public static var wouldBlock: Errno { .init(rawValue: EWOULDBLOCK) }
#if !os(WASI)
  @_alwaysEmitIntoClient
  public static var tooManyReferences: Errno { .init(rawValue: ETOOMANYREFS) }
  @_alwaysEmitIntoClient
  public static var tooManyRemoteLevels: Errno { .init(rawValue: EREMOTE) }
#endif
#if SYSTEM_PACKAGE_DARWIN
  @_alwaysEmitIntoClient
  public static var noSuchPolicy: Errno { .init(rawValue: ENOPOLICY) }
#endif
#if !os(Windows)
  @_alwaysEmitIntoClient
  public static var notRecoverable: Errno { .init(rawValue: ENOTRECOVERABLE) }
  @_alwaysEmitIntoClient
  public static var previousOwnerDied: Errno { .init(rawValue: EOWNERDEAD) }
#endif
#if os(FreeBSD)
  @_alwaysEmitIntoClient
  public static var notCapable: Errno { .init(rawValue: ENOTCAPABLE) }
  @_alwaysEmitIntoClient
  public static var capabilityMode: Errno { .init(rawValue: ECAPMODE) }
  @_alwaysEmitIntoClient
  public static var integrityCheckFailed: Errno { .init(rawValue: EINTEGRITY) }
#endif
#if SYSTEM_PACKAGE_DARWIN
  @_alwaysEmitIntoClient
  public static var outputQueueFull: Errno { .init(rawValue: EQFULL) }
#endif
#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  @_alwaysEmitIntoClient
  public static var lastErrnoValue: Errno { .init(rawValue: ELAST) }
#endif
}

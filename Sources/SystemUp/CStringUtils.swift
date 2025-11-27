import CUtility
import SystemPackage
import SystemLibc

public enum CStringUtils {}

// MARK:  <string.h>
public extension CStringUtils {
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func length(of string: borrowing some CString, bytesLimit: Int? = nil) -> Int {
    string.withUnsafeCString { string in
      if let bytesLimit {
        SystemLibc.strnlen(string, bytesLimit)
      } else {
        SystemLibc.strlen(string)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copy(src: borrowing some CString, dest: UnsafeMutablePointer<CChar>, bytesLimit: Int? = nil, returnsTrailPointer: Bool = false) -> UnsafeMutablePointer<CChar> {
    src.withUnsafeCString { src in
      if let bytesLimit {
        returnsTrailPointer ? SystemLibc.stpncpy(dest, src, bytesLimit) : SystemLibc.strncpy(dest, src, bytesLimit)
      } else {
        returnsTrailPointer ? SystemLibc.stpcpy(dest, src) : SystemLibc.strcpy(dest, src)
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func concatenate(src: borrowing some CString, dest: UnsafeMutablePointer<CChar>, bytesLimit: Int? = nil) -> UnsafeMutablePointer<CChar> {
    src.withUnsafeCString { src in
      if let bytesLimit {
        SystemLibc.strncat(dest, src, bytesLimit)
      } else {
        SystemLibc.strcat(dest, src)
      }
    }
  }

  enum ComparisonResult {
    case orderedAscending
    case orderedSame
    case orderedDescending

    @_alwaysEmitIntoClient
    @inlinable @inline(__always)
    init(_ r: Int32) {
      if r == 0 {
        self = .orderedSame
      } else if r > 0 {
        self = .orderedDescending
      } else {
        self = .orderedAscending
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func compare(_ s1: borrowing some CString, _ s2: borrowing some CString, bytesLimit: Int? = nil) -> ComparisonResult {
    let r = s1.withUnsafeCString { s1 in
      s2.withUnsafeCString { s2 in
        if let bytesLimit {
          SystemLibc.strncmp(s1, s2, bytesLimit)
        } else {
          SystemLibc.strcmp(s1, s2)
        }
      }
    }
    return .init(r)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func search(_ string: UnsafePointer<CChar>, character: UInt8, locatesLast: Bool = false) -> UnsafePointer<CChar>? {
    let r = if locatesLast {
      SystemLibc.strrchr(string, numericCast(character))
    } else {
      SystemLibc.strchr(string, numericCast(character))
    }

    return .init(r)
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func span(_ string: borrowing some CString, charset: borrowing some CString, reverse: Bool = false) -> Int {
    string.withUnsafeCString { string in
      charset.withUnsafeCString { charset in
        if reverse {
          SystemLibc.strcspn(string, charset)
        } else {
          SystemLibc.strspn(string, charset)
        }
      }
    }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func firstCharacter(in string: UnsafePointer<CChar>, charset: borrowing some CString) -> UnsafePointer<CChar>? {
    charset.withUnsafeCString { charset in
      SystemLibc.strpbrk(string, charset)
    }.map { .init($0) }
  }

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func search(_ string: UnsafePointer<CChar>, substring: borrowing some CString, caseSensitive: Bool = true) -> UnsafePointer<CChar>? {
    substring.withUnsafeCString { substring in
      if caseSensitive {
        SystemLibc.strstr(string, substring)
      } else {
        SystemLibc.strcasestr(string, substring)
      }
    }.map { .init($0) }
  }

  #if canImport(Darwin) || os(FreeBSD)
  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func search(_ string: UnsafePointer<CChar>, substring: borrowing some CString, bytesLimit: Int) -> UnsafePointer<CChar>? {
    substring.withUnsafeCString { substring in
      SystemLibc.strnstr(string, substring, bytesLimit)
    }.map { .init($0) }
  }
  #endif

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copy(_ string: borrowing some CString, bytesLimit: Int? = nil) throws(Errno) -> DynamicCString {
    try SyscallUtilities.unwrap {
      string.withUnsafeCString { string in
        if let bytesLimit {
          SystemLibc.strndup(string, bytesLimit)
        } else {
          SystemLibc.strdup(string)
        }
      }
    }.map { DynamicCString(cString: $0) }.get()
  }
}

public extension DynamicCString {

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func copy(bytes: borrowing some ContiguousUTF8Bytes & ~Copyable & ~Escapable) throws(Errno) -> Self {
    try bytes.withContiguousUTF8Bytes { buffer throws(Errno) in
      try CStringUtils.copy(buffer.baseAddress!, bytesLimit: buffer.count)
    }
  }

}

// TODO
/*

 public func memchr(_ __s: UnsafeRawPointer!, _ __c: Int32, _ __n: Int) -> UnsafeMutableRawPointer!

 public func memcpy(_ __dst: UnsafeMutableRawPointer!, _ __src: UnsafeRawPointer!, _ __n: Int) -> UnsafeMutableRawPointer!

 public func memmove(_ __dst: UnsafeMutableRawPointer!, _ __src: UnsafeRawPointer!, _ __len: Int) -> UnsafeMutableRawPointer!

 public func memset(_ __b: UnsafeMutableRawPointer!, _ __c: Int32, _ __len: Int) -> UnsafeMutableRawPointer!

 public func strtok(_ __str: UnsafeMutablePointer<CChar>!, _ __sep: UnsafePointer<CChar>!) -> UnsafeMutablePointer<CChar>!

 public func strxfrm(_ __s1: UnsafeMutablePointer<CChar>!, _ __s2: UnsafePointer<CChar>!, _ __n: Int) -> Int

 public func strtok_r(_ __str: UnsafeMutablePointer<CChar>!, _ __sep: UnsafePointer<CChar>!, _ __lasts: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!) -> UnsafeMutablePointer<CChar>!

 public func memccpy(_ __dst: UnsafeMutableRawPointer!, _ __src: UnsafeRawPointer!, _ __c: Int32, _ __n: Int) -> UnsafeMutableRawPointer!

 @available(macOS 10.9, *)
 public func memset_s(_ __s: UnsafeMutableRawPointer!, _ __smax: Int, _ __c: Int32, _ __n: Int) -> errno_t

 @available(macOS 10.7, *)
 public func memmem(_ __big: UnsafeRawPointer!, _ __big_len: Int, _ __little: UnsafeRawPointer!, _ __little_len: Int) -> UnsafeMutableRawPointer!

 @available(macOS 10.5, *)
 public func memset_pattern4(_ __b: UnsafeMutableRawPointer!, _ __pattern4: UnsafeRawPointer!, _ __len: Int)

 @available(macOS 10.5, *)
 public func memset_pattern8(_ __b: UnsafeMutableRawPointer!, _ __pattern8: UnsafeRawPointer!, _ __len: Int)

 @available(macOS 10.5, *)
 public func memset_pattern16(_ __b: UnsafeMutableRawPointer!, _ __pattern16: UnsafeRawPointer!, _ __len: Int)

 @available(macOS 15.4, *)
 public func strchrnul(_ __s: UnsafePointer<CChar>!, _ __c: Int32) -> UnsafeMutablePointer<CChar>!

 public func strlcat(_ __dst: UnsafeMutablePointer<CChar>!, _ __source: UnsafePointer<CChar>!, _ __size: Int) -> Int

 public func strlcpy(_ __dst: UnsafeMutablePointer<CChar>!, _ __source: UnsafePointer<CChar>!, _ __size: Int) -> Int

 public func strmode(_ __mode: Int32, _ __bp: UnsafeMutablePointer<CChar>!)

 public func strsep(_ __stringp: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, _ __delim: UnsafePointer<CChar>!) -> UnsafeMutablePointer<CChar>!

 public func swab(_: UnsafeRawPointer!, _: UnsafeMutableRawPointer!, _ __len: Int)

 @available(macOS 10.12.1, *)
 public func timingsafe_bcmp(_ __b1: UnsafeRawPointer!, _ __b2: UnsafeRawPointer!, _ __len: Int) -> Int32

 @available(macOS 11.0, *)
 public func strsignal_r(_ __sig: Int32, _ __strsignalbuf: UnsafeMutablePointer<CChar>!, _ __buflen: Int) -> Int32


 */

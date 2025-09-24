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

  @_alwaysEmitIntoClient @inlinable @inline(__always)
  static func search(_ string: UnsafePointer<CChar>, substring: borrowing some CString, bytesLimit: Int) -> UnsafePointer<CChar>? {
    substring.withUnsafeCString { substring in
      SystemLibc.strnstr(string, substring, bytesLimit)
    }.map { .init($0) }
  }

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


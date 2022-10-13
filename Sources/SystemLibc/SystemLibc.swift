#if canImport(Darwin)
@_exported import Darwin.C
#elseif canImport(Glibc)
@_exported import Glibc
#endif

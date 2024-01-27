#if canImport(Darwin)
@_exported import Darwin.C
#elseif canImport(Glibc)
@_exported import Glibc
#endif
@_exported import CSystemUp

#if os(Linux)
@_silgen_name("vasprintf")
public func vasprintf(_ ret: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, _ format: UnsafePointer<CChar>!, _ va: CVaListPointer) -> Int32
#endif

#if canImport(Glibc)
@_silgen_name("gnu_get_libc_version")
public func gnuGetLibcVersion() -> UnsafePointer<CChar>

@_silgen_name("gnu_get_libc_release")
public func release() -> UnsafePointer<CChar>
#endif

#if canImport(Darwin)
@_silgen_name("_NSGetEnviron")
public func NSGetEnviron() -> UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>>
#endif

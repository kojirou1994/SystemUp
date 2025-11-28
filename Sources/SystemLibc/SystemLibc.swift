#if canImport(CSystemUp)
#if canImport(Darwin)
@_exported import Darwin.C
#elseif canImport(Glibc)
@_exported import Glibc
#elseif canImport(Musl)
@_exported import Musl
#endif
@_exported import CSystemUp
#else
@_exported import LittleC
#endif

#if os(Linux)
@_silgen_name("vasprintf")
public func vasprintf(_ ret: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, _ format: UnsafePointer<CChar>!, _ va: CVaListPointer) -> Int32
#endif

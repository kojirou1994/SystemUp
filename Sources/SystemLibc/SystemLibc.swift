#if canImport(Darwin)
@_exported import Darwin.C
#elseif canImport(Glibc)
@_exported import Glibc
#endif


#if os(Linux)
@_silgen_name("vasprintf")
public func vasprintf(_ ret: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, _ format: UnsafePointer<CChar>!, _ va: CVaListPointer) -> Int32
#endif

import SystemPackage
import SyscallValue

extension SyscallUtilities {
  @inlinable
  public static func preallocateSyscall<S: FixedWidthInteger, R: SyscallValue>(_ body: (_ mode: PreAllocateCallMode) -> Result<S, Errno>) -> Result<R, Errno> {
    switch body(.getSize) {
    case .failure(let err): return .failure(err)
    case .success(let bufsize):
      do {
        let capacity = Int(bufsize)
        let v = try R(capacity: capacity) { ptr in
          let realsize = try body(.getValue(.init(start: ptr, count: capacity))).get()
          return Int(realsize)
        }
        return .success(v)
      } catch let err as Errno {
        return .failure(err)
      } catch { fatalError() }
    }
  }
}

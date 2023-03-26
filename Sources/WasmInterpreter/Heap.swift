import Foundation

struct Heap {
    let pointer: UnsafeMutablePointer<UInt8>
    let size: Int

    func isValid(byteOffset: Int, length: Int) -> Bool {
        (byteOffset + length) <= size
    }
}

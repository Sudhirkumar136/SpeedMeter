import Darwin
import Foundation

public enum InterfaceCounterReader {
    public static func read() throws -> [InterfaceCounter] {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var size = 0
        let sizeResult = mib.withUnsafeMutableBufferPointer { pointer in
            sysctl(pointer.baseAddress, u_int(pointer.count), nil, &size, nil, 0)
        }
        guard sizeResult == 0 else { throw posixError() }
        guard size > 0 else { return [] }

        let buffer = UnsafeMutableRawPointer.allocate(
            byteCount: size,
            alignment: MemoryLayout<if_msghdr2>.alignment
        )
        defer { buffer.deallocate() }
        let readResult = mib.withUnsafeMutableBufferPointer { pointer in
            sysctl(pointer.baseAddress, u_int(pointer.count), buffer, &size, nil, 0)
        }
        guard readResult == 0 else { throw posixError() }

        var counters: [String: InterfaceCounter] = [:]
        var offset = 0
        while offset + MemoryLayout<if_msghdr2>.size <= size {
            let messageLength = Int(buffer.advanced(by: offset).load(as: UInt16.self))
            guard messageLength > 0, offset + messageLength <= size else { break }
            let type = buffer.advanced(by: offset + 3).load(as: UInt8.self)
            if type == RTM_IFINFO2, messageLength >= MemoryLayout<if_msghdr2>.size {
                let message = buffer.advanced(by: offset).load(as: if_msghdr2.self)
                let addressOffset = offset + MemoryLayout<if_msghdr2>.size
                let nameLengthOffset = addressOffset + (MemoryLayout<sockaddr_dl>.offset(of: \.sdl_nlen) ?? 5)
                let nameOffset = addressOffset + (MemoryLayout<sockaddr_dl>.offset(of: \.sdl_data) ?? 8)
                if nameLengthOffset < offset + messageLength,
                   nameOffset <= offset + messageLength {
                    let nameLength = Int(buffer.advanced(by: nameLengthOffset).load(as: UInt8.self))
                    guard nameLength > 0, nameOffset + nameLength <= offset + messageLength else {
                        offset += messageLength
                        continue
                    }
                    let nameBytes = UnsafeRawBufferPointer(
                        start: buffer.advanced(by: nameOffset),
                        count: nameLength
                    )
                    let interfaceName = String(decoding: nameBytes, as: UTF8.self)
                    let flags = message.ifm_flags
                    counters[interfaceName] = InterfaceCounter(
                        name: interfaceName,
                        received: message.ifm_data.ifi_ibytes,
                        sent: message.ifm_data.ifi_obytes,
                        isUp: flags & Int32(IFF_UP) != 0,
                        isRunning: flags & Int32(IFF_RUNNING) != 0
                    )
                }
            }
            offset += messageLength
        }
        return counters.values.sorted { $0.name < $1.name }
    }

    private static func posixError() -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
    }
}

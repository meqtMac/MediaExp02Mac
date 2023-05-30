//
//  socket.swift
//  MediaExp02Server
//
//  Created by 蒋艺 on 2023/5/28.
//

import Foundation
import Darwin

public struct Socket {
    public let socketFileDescriptor: Int32
    
    public func sendData(_ data: Data) throws {
        try data.withUnsafeBytes { bufferPointer in
            let bufferAddress = bufferPointer.bindMemory(to: UInt8.self).baseAddress
            let bufferLength = bufferPointer.count
            
            let bytesSent = write(socketFileDescriptor, bufferAddress, bufferLength)
            guard bytesSent != -1 else {
                throw SocketError.sendFailed(String(errno))
            }
        }
    }
    
    public func receiveData() throws -> Data {
        var receivedData = Data()
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        let bytesRead = read(socketFileDescriptor, &buffer, bufferSize)
        guard bytesRead >= 0 else {
            throw SocketError.receiveFailed(String(errno))
        }
        receivedData.append(contentsOf: buffer[0..<bytesRead])
        return receivedData
    }
    
    public mutating func close() {
        if socketFileDescriptor != -1 {
            Darwin.close(socketFileDescriptor)
        }
    }
    
    public func sendFile(data: Data) throws {
        let fileSize = data.count
        let fileSizeData = withUnsafeBytes(of: fileSize.bigEndian) { Data($0) }
        
        try sendData(fileSizeData) // Send the total file size to the other end
        print("send fileSize: \(fileSize)")
        let bufferSize = 4096 // Adjust the buffer size as per your needs
        
        var bytesSent = 0
        
        while bytesSent < fileSize {
            let remainingSize = fileSize - bytesSent
            let bufferSizeToSend = min(bufferSize, remainingSize)
            let buffer = data.subdata(in: bytesSent..<bytesSent+bufferSizeToSend)
            
            try sendData(buffer) // Send the buffer of file data
            
            bytesSent += bufferSizeToSend
        }
        print("finished send bytes: \(bytesSent)")
    }
    
    func extractInt(from data: Data) -> Int? {
        guard data.count == MemoryLayout<Int>.size else {
            return nil // Data size does not match the size of an Int
        }
        
        var intValue: Int = 0
        
        data.withUnsafeBytes { rawBufferPointer in
            let bufferPointer = rawBufferPointer.bindMemory(to: Int.self)
            intValue = bufferPointer.first!.bigEndian
        }
        
        return intValue
    }
    
    public func receiveFile() throws -> Data? {
        let fileSizeData = try receiveData()
        
        guard let fileSize = extractInt(from: fileSizeData.subdata(in: 0..<MemoryLayout<Int>.size)) else {
            return nil
        }
        print("receiving file size: \(fileSize)")
        
        var receivedData = Data()
        var bytesReceived = 0
        
        let bufferSize = 4096 // Adjust the buffer size as per your needs
        
        while bytesReceived < fileSize {
            let remainingSize = fileSize - bytesReceived
            let bufferSizeToReceive = min(bufferSize, remainingSize)
            
            let buffer = try receiveData() // Receive the buffer of file data
            receivedData.append(buffer)
            
            bytesReceived += bufferSizeToReceive
        }
        print("finished receiving file.")
        
        return receivedData
    }
}

public enum SocketError: Error {
    case sendFailed(String)
    case receiveFailed(String)
}

public func sockaddr_cast(_ ptr: UnsafeMutableRawPointer) -> UnsafeMutablePointer<sockaddr> {
    return ptr.assumingMemoryBound(to: sockaddr.self)
}

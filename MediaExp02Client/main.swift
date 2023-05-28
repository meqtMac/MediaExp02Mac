//
//  main.swift
//  MediaExp02Client
//
//  Created by 蒋艺 on 2023/5/29.
//

import Foundation
import Darwin

func startClient() {
    let clientPort: UInt16 = 12345
    var clientAddress = sockaddr_in()
    clientAddress.sin_family = sa_family_t(AF_INET)
    clientAddress.sin_port = clientPort.bigEndian
    
    let ptonResult = withUnsafeMutableBytes(of: &clientAddress.sin_addr.s_addr) { rawBuffer in
        inet_pton(AF_INET, "127.0.0.1", rawBuffer.baseAddress!)
    }
    
   let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
    guard socketFileDescriptor != -1 else {
        print("Failed to create socket")
        return
    }
    
    let connectResult = connect(socketFileDescriptor, sockaddr_cast(&clientAddress), socklen_t(MemoryLayout<sockaddr_in>.size))
    guard connectResult != -1 else {
        print("Failed to connect")
        return
    }
    
    var socket = Socket(socketFileDescriptor: socketFileDescriptor)
    
    do {
        let filesData = try socket.receiveData()
        guard let files = socket.extractInt(from: filesData) else {
            print("Failed to get file numbers")
            return
        }
        print("\(files) to receive")
        try socket.sendData("received \(files) to accept".data(using: .utf8)!)
        
        for _ in 0..<files{
            if let fileData = try socket.receiveFile() {
                try socket.sendData("received \(fileData.count) bytes".data(using: .utf8)!)
                print("received \(fileData.count) bytes")
            }
        }
    }catch{
        print("Error: \(error)")
    }
    
    socket.close()
}

startClient()

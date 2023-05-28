//
//  main.swift
//  MediaExp02Client
//
//  Created by 蒋艺 on 2023/5/28.
//

import Foundation
import Darwin

func startServer() {
    let serverPort: UInt16 = 12345
    
    var serverAddress = sockaddr_in()
    serverAddress.sin_family = sa_family_t(AF_INET)
    serverAddress.sin_port = serverPort.bigEndian
    serverAddress.sin_addr.s_addr = INADDR_ANY
    
    let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
    guard socketFileDescriptor != -1 else {
        print("Failed to create socket")
        return
    }
    
    let bindResult = bind(socketFileDescriptor, sockaddr_cast(&serverAddress), socklen_t(MemoryLayout<sockaddr_in>.size))
    
    guard bindResult != -1 else {
        print("Failed to bind socket")
        return
    }
    
    let listenResult = listen(socketFileDescriptor, SOMAXCONN)
    guard listenResult != -1 else {
        print("Failed to listen on socket")
        return
    }
    
    print("Server started. Listening on port \(serverPort)")
    
    while true {
        let clientSocketFileDescriptor = accept(socketFileDescriptor, nil, nil)
        guard clientSocketFileDescriptor != -1 else {
            print("Failed to accept connection")
            continue
        }
        
        var clientSocket = Socket(socketFileDescriptor: clientSocketFileDescriptor)
        print("Client connected")
        
        do {
            // Send message to client indicating the expected size of the data
            let fileCount = 10
            let fileCountData = withUnsafeBytes(of: fileCount.bigEndian) { Data($0) }
            try clientSocket.sendData(fileCountData)
            print("10 files to send.")
            let _ = try clientSocket.receiveData()
            print("start sending files:")
            
            for i in 1...10 {
                let filePath = "Resources/\(i).bin"
                if let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                    try clientSocket.sendFile(data: fileData)
                    print("Sent file \(filePath) to client")
                    let _ = try clientSocket.receiveData()
                } else {
                    print("Failed to read file: \(filePath)")
                }
            }
        } catch {
            print("Error: \(error)")
        }
        
        clientSocket.close()
        print("Client connection closed")
    }
    
    close(socketFileDescriptor)
    print("Server stopped")
}

startServer()

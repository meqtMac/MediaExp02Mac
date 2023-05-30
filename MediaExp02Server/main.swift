//
//  main.swift
//  MediaExp02Client
//
//  Created by 蒋艺 on 2023/5/28.
//

import Foundation
import Darwin

func startServer() {
   /** after try, I found for Xcode Command Line Tool, for example you have a Project, and a Target myServer under MyServer Folder, and you have files maybe in Resources/ with name 1.bin, you can add it by copy Files and give a custom path for example Bins/, don't click copy only when installing, the add 1.bin file in below. After that you can access the file with
     ```
         let fileURLinBundle = Bundle.main.url(forResource: "1", withExtension: "bin", subdirectory: "Bins")
             print("fileURL:", fileURLinBundle)
             if let url = fileURLinBundle {
                 if let data = try? Data(contentsOf: url) {
                     print(data.count)
                }
             }
         }
     ```
     */
   
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
            // send meta data of video
            try clientSocket.sendData(fileCountData)
            print("10 files to send.")
            
            let _ = try clientSocket.receiveData()
            print("start sending files:")
            
            for i in 1...10 {
                if let fileURL = Bundle.main.url(forResource: "\(i)", withExtension: "bin", subdirectory: "Bins") {
                    if let fileData = try? Data(contentsOf: fileURL) {
                        do {
                            try clientSocket.sendFile(data: fileData)
                        }catch{
                            print(error.localizedDescription)
                        }
                        print("\tSent \(fileURL.lastPathComponent) to client")
                        // receive conformation before send next file.
                        let _ = try clientSocket.receiveData()
                    }else{
                        print("\tFail to read \(i).bin")
                    }
                }else{
                    print("Failed to get fileURL of \(i).bin")
                }
           }
        } catch {
            print("Error: \(error)")
        }
        
        // close client socket after sending video finished.
        clientSocket.close()
        print("Client connection closed")
    }
    
    close(socketFileDescriptor)
    print("Server stopped")
}

startServer()

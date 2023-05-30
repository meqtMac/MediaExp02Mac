//
//  MediaViewModel.swift
//  MediaExp02Mac
//
//  Created by 蒋艺 on 2023/5/29.
//

//import Foundation
import SwiftUI
import Dispatch

let frameWidth = 832
let frameHeight = 480
let blockFrames = 50

class MediaViewModel: ObservableObject {
    @Published var cachedFrames: Int = 0
    @Published var currentFrame: Frame?
    
    func updateCurrentFrame() -> Int? {
        self.frameQueue.sync{
            if !frames.isEmpty {
                currentFrame = frames.removeFirst()
            }
        }
        return currentFrame?.frameId
    }
    
    /// fifo operation
    private var binData: [Bin] = []
    /// protect exclusive access to binData
    private let binQueue = DispatchQueue(label: "meqtmac.mediaExp02.bin")
    private let binSemaphore = DispatchSemaphore(value: 0)
    
    private var YpCbCrBlocks: [YpCbCrBlock] = []
    /// protect exclusive access to blocks
    private let blockQueue = DispatchQueue(label: "meqtmac.medixExp02.block")
    private var blockSemaphore = DispatchSemaphore(value: 0)
    /// use multithread to accelearte decodeing and with qos operation to have lower seqId with higher priority
    private let decodingQueue = DispatchQueue(label: "meqtmac.mediaExp02.decodingQueue", attributes: .concurrent)
    
    public var frames: [Frame] = []
    /// protect exclusive access to frames
    private let frameQueue = DispatchQueue(label: "meqtmac.medixExp02.frames")
    // private var frameSemaphore = DispatchSemaphore(value: 0)
    
    private var isDecoderThreadRunning = false
    
    func startProcessing() {
        isDecoderThreadRunning = true
        
        // Start the socket thread
        DispatchQueue.global().async {
            self.socketThread()
        }
        
        // Start the decoder thread
        DispatchQueue.global().async {
            self.decoderThread()
        }
        
        DispatchQueue.global().async {
            self.frameThread()
        }
    }
    
    func stopProcessing() {
        isDecoderThreadRunning = false
    }
    
    private func socketThread() {
        do {
            let clientPort: UInt16 = 12345
            var clientAddress = sockaddr_in()
            clientAddress.sin_family = sa_family_t(AF_INET)
            clientAddress.sin_port = clientPort.bigEndian
            
            let _ = withUnsafeMutableBytes(of: &clientAddress.sin_addr.s_addr) { rawBuffer in
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
            
            let filesData = try socket.receiveData()
            guard let files = socket.extractInt(from: filesData) else {
                print("Failed to get file numbers")
                return
            }
            print("\(files) to receive")
            try socket.sendData("received \(files) to accept".data(using: .utf8)!)
            
            for seq in 0..<files {
                if let fileData = try socket.receiveFile() {
                    try socket.sendData("received \(fileData.count) bytes".data(using: .utf8)!)
                    print("received \(fileData.count) bytes")
                    
                    binQueue.sync {
                        binData.append(Bin(seqId: seq, data: fileData))
                        binSemaphore.signal() // Signal the decoder thread that data is available
                    }
                }
            }
            
            socket.close()
        } catch {
            print("Error: \(error)")
        }
    }
    
    private func decoderThread() {
        while isDecoderThreadRunning {
            binSemaphore.wait()
            var bin: Bin?
            
            binQueue.sync {
                bin = binData.removeFirst()
            }
            
            if let processingBin = bin {
                var block: YpCbCrBlock?
                if let processedData = decoder(seqId: processingBin.seqId, inputData: processingBin.data) {
                    block = YpCbCrBlock(seqId: processingBin.seqId, data: processedData)
                }
                
                if let decodedBlock = block {
                    self.blockQueue.sync(flags: .barrier){
                        self.YpCbCrBlocks.append(decodedBlock)
                    }
                    self.blockSemaphore.signal()
                }
            }
        }
    }
    
    private func frameThread() {
        while isDecoderThreadRunning {
            blockSemaphore.wait()
            var block: YpCbCrBlock?
            
            blockQueue.sync(flags: .barrier) {
                block = YpCbCrBlocks.removeFirst()
            }
            
            if let processingBlock = block {
                let renderedFrames = getGrayscaleImagesFromYpChannel(block: processingBlock)
                
                DispatchQueue.main.sync {
                    self.cachedFrames += blockFrames
                }
                
                self.frameQueue.sync{
                    self.frames.append(contentsOf: renderedFrames)
                }
            }
        }
    }
}

struct Bin: Comparable{
    static func < (lhs: Bin, rhs: Bin) -> Bool {
        return lhs.seqId < rhs.seqId
    }
    
    // bin sequence, start from 0
    let seqId: Int
    let data: Data
}

struct YpCbCrBlock: Comparable {
    static func < (lhs: YpCbCrBlock, rhs: YpCbCrBlock) -> Bool {
        lhs.seqId < rhs.seqId
    }
    
    // block sequence, start from 0, same as the bin it decodered from
    let seqId: Int
    let data: Data
}

struct Frame {
    let frameId: Int
    let cgImage: CGImage
}


//
//  Frames.swift
//  MediaExp02Mac
//
//  Created by 蒋艺 on 2023/5/29.
//

import Foundation

import Accelerate.vImage

func getGrayscaleImagesFromYpChannel(block: YpCbCrBlock) -> [Frame] {
    var frames: [Frame] = []
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let bytesPerPixel = 1
    let bitsPerComponent = 8
    let bytesPerRow = bytesPerPixel * frameWidth
    let bitmapInfo = CGImageAlphaInfo.none.rawValue
    
    for i in 0..<blockFrames {
        let frameBytes = frameWidth*frameHeight*3/2
        let frameGrayBytes = frameWidth&frameHeight
        let frameGrayRange = i*frameBytes ..< i*frameBytes+frameGrayBytes
        let frameId = block.seqId * blockFrames + i
        print("rendering \(frameId) frames.")
        
        var frameData = block.data.subdata(in: frameGrayRange)
        
        frameData.withUnsafeMutableBytes { rawBuffer in
            guard let context = CGContext(
                data: rawBuffer.baseAddress,
                width: frameWidth,
                height: frameHeight,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )else {
                print("get frame error")
                fatalError("can't get frames")
            }
            
            guard let image = context.makeImage() else{
                fatalError("can't create image.")
            }
            frames.append(Frame(frameId: frameId, cgImage: image))
        }
    }
    return frames
}

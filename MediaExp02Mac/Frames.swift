//
//  Frames.swift
//  MediaExp02Mac
//
//  Created by 蒋艺 on 2023/5/29.
//

//import Foundation
import Accelerate
import simd

func getGrayscaleImagesFromYpChannel(block: YpCbCrBlock) -> [Frame] {
    var frames: [Frame] = []
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let bytesPerPixel = 1
    let bitsPerComponent = 8
    let bytesPerRow = bytesPerPixel * frameWidth
    let bitmapInfo = CGImageAlphaInfo.none.rawValue
    
    for i in 0..<blockFrames {
        let frameBytes = frameWidth*frameHeight*3/2
        let frameGrayBytes = frameWidth*frameHeight
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

func getFramesFrom420YpCbCrBlock(block: YpCbCrBlock) -> [Frame] {
    var frames: [Frame] = []
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * frameWidth
    
    // Create RGB color space
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    for i in 0..<blockFrames {
        let frameBytes = frameWidth*frameHeight*3/2
        let frameGrayBytes = frameWidth*frameHeight
        let frameYpRange = i*frameBytes ..< i*frameBytes+frameGrayBytes
        let frameCbRange = i*frameBytes + frameGrayBytes ..< i*frameBytes + 5*frameGrayBytes/4
        let frameCrRange = i*frameBytes + 5*frameGrayBytes/4 ..< i*frameBytes + frameBytes
        let frameId = block.seqId * blockFrames + i
        print("rendering \(frameId) frames.")
        
        let YpData = Array(block.data[frameYpRange])
        let CbData = Array(block.data[frameCbRange])
        let CrData = Array(block.data[frameCrRange])
        //TODO: convert 420YpCbCr to ARGB
        var imageBuffer = convert420YpCbCrToARGB8888(YpData: YpData, CbData: CbData, CrData: CrData)
        imageBuffer.withUnsafeMutableBytes { rawBuffer in
            guard let context = CGContext(
                data: rawBuffer.baseAddress,
                width: frameWidth,
                height: frameHeight,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            else {
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

func convert420YpCbCrToARGB8888(YpData: [UInt8], CbData: [UInt8], CrData: [UInt8]) -> [UInt8] {
    var argbData = [Float](repeating: 0, count: YpData.count * 4)
    let matrix = simd_float3x3( columns: (simd_float3(1.164, 0.0, 1.596),
                                          simd_float3(1.164, -0.813, -0.391),
                                          simd_float3(1.164, 2.018, 0.0)) )
    
   for row in 0..<frameHeight{
        for column in 0..<frameWidth{
            let y = simd_float1(YpData[row * frameWidth + column]) - 16
            let cb = simd_float1(CbData[(row/2 * frameWidth/2) + column / 2]) - 128
            let cr = simd_float1(CrData[(row/2 * frameWidth/2) + column / 2]) - 128
            let yuvVector = simd_float3(y, cb, cr)
            let rgbVector = matrix * yuvVector
            
            argbData[(row*frameWidth+column)*4+1] = rgbVector[0]
            argbData[(row*frameWidth+column)*4+2] = rgbVector[1]
            argbData[(row*frameWidth+column)*4+3] = rgbVector[2]
        }
    }
    
    return [UInt8](unsafeUninitializedCapacity: YpData.count*4) { buffer, initializedCount in
        initializedCount = YpData.count*4
        vDSP.convertElements(of: argbData, to: &buffer, rounding: .towardNearestInteger)
    }
}

//
//  Decoder.swift
//  MediaExp02Mac
//
//  Created by 蒋艺 on 2023/5/28.
//

import Foundation

/// Runs the decoder operation on the input data and returns the output data.
/// - Parameters:
///   - inputData: The input data to be decoded.
/// - Returns: The output data produced by the decoder, or `nil` if the decoder failed or the output file is not found.
func runDecoder(inputData: Data) -> Data? {
    /// The name of the temporary input file.
    let inputFileName = "tempInput.bin"
    /// The name of the temporary output file.
    let outputFileName = "tempYuv"
    
    let fileManager = FileManager.default
    
//    // Create a temporary directory within the user's temporary directory
//    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Decoder")
//
//    // Create the temporary directory if it doesn't exist
//    try? fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil)
//
    // Create the temporary input file path
    let inputFilePath = fileManager.temporaryDirectory.appendingPathComponent(inputFileName)
    
    // Write the input data to the temporary input file
    do {
        try inputData.write(to: inputFilePath)
    } catch {
        print("Error writing the input data to the temporary input file: \(error)")
        return nil
    }
    
    let outputFilePath = fileManager.temporaryDirectory.appendingPathComponent(outputFileName)
    
    // Set the decoder path and output file path
    let decoderPath = Bundle.main.path(forResource: "TAppDecoder", ofType: nil)!
    
    let task = Process()
    task.launchPath = decoderPath
    task.arguments = ["-b", inputFilePath.path, "-o", outputFilePath.path]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    task.launch()
    task.waitUntilExit()
    
    // Read output data from the output file
    guard let outputData = try? Data(contentsOf: outputFilePath) else {
        return nil
    }
    
    // Remove the temporary input file
    do {
        try fileManager.removeItem(at: inputFilePath)
    } catch {
        print("Error deleting the temporary input file: \(error)")
    }
    
    // Remove the temporary output file
    do {
        try fileManager.removeItem(at: outputFilePath)
    } catch {
        print("Error deleting the temporary output file: \(error)")
    }
    
    return outputData
}

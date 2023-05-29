//
//  ContentView.swift
//  MediaExp02Mac
//
//  Created by 蒋艺 on 2023/5/28.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var meidaViewModel = MediaViewModel()
//    var bytesCount = 0
    
    var body: some View {
        VStack {
            Button("Start Processing") {
                meidaViewModel.startProcessing()
            }
            
            Button("Stop Processing") {
                meidaViewModel.stopProcessing()
            }
            
            Text("\(meidaViewModel.currentFrame)")
            
            if !meidaViewModel.frames.isEmpty {
                Image(decorative: meidaViewModel.frames.first!.cgImage, scale: 1.0)
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

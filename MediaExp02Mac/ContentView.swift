//
//  ContentView.swift
//  MediaExp02Mac
//
//  Created by 蒋艺 on 2023/5/28.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var meidaViewModel = MediaViewModel()
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Button("Start Processing") {
                meidaViewModel.startProcessing()
            }
            
            Button("Stop Processing") {
                meidaViewModel.stopProcessing()
            }
            
           if let image = meidaViewModel.currentFrame {
                Image(decorative: image.cgImage, scale: 1)
                    .overlay(alignment: .bottomLeading) {
                        Text("\(image.frameId)")
                }
            }
        }
        .padding()
        .onReceive(timer) { _  in
            meidaViewModel.updateCurrentFrame()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

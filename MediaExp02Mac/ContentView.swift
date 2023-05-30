//
//  ContentView.swift
//  MediaExp02Mac
//
//  Created by 蒋艺 on 2023/5/28.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var meidaViewModel = MediaViewModel()
    @State private var isPaused = false
    @State private var speedConstant = 6
    @State private var counter = 0
    
    let timer = Timer.publish(every: 0.02/6.0, on: .main, in: .common).autoconnect()
   
    var body: some View {
        VStack {
            Button("Start Processing") {
                meidaViewModel.startProcessing()
                isPaused = false
            }
            if let image = meidaViewModel.currentFrame {
                ZStack(alignment: .bottom) {
                    Image(decorative: image.cgImage, scale: 1)
                        .overlay(alignment: .bottom) {
                            VStack{
                                HStack{
                                    Button {
                                        isPaused.toggle()
                                    } label: {
                                        if isPaused {
                                            Image(systemName: "play.fill")
                                        }else{
                                            Image(systemName: "pause.fill")
                                        }
                                    }
                                    .padding(.horizontal)
                                    Picker("Speed", selection: $speedConstant) {
                                        Text("1/4").tag(24)
                                        Text("1/2").tag(12)
                                        Text("normal").tag(6)
                                        Text("3/2").tag(4)
                                        Text("2").tag(3)
                                    }
                                    .pickerStyle(.segmented)
                                    .padding(.horizontal)
                                }
                                ZStack{
                                    ProgressView(value: Double(meidaViewModel.cachedFrames), total: 500)
                                        .tint(.gray)
                                    Slider(value: .constant(Double(image.frameId)), in: 0.0...500)
                                }
                            }
                        }
                    
                }
            }
        }
        .padding()
        .onReceive(timer) { _  in
            if !isPaused {
                counter += 1
                if counter % speedConstant == 0 {
                    let frameid = meidaViewModel.updateCurrentFrame()
                    if frameid == 499 {
                        isPaused = true
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

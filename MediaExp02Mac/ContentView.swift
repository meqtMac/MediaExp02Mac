//
//  ContentView.swift
//  MediaExp02Mac
//
//  Created by 蒋艺 on 2023/5/28.
//

import SwiftUI

struct ContentView: View {
    var bytesCount = 0
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
       }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

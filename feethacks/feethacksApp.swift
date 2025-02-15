//
//  feethacksApp.swift
//  feethacks
//
//  Created by Taylor Tam on 2/14/25.
//

import SwiftUI


struct UIViewWrapper<V: UIView>: UIViewRepresentable {
    
    let view: UIView
    
    func makeUIView(context: Context) -> some UIView { view }
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}

@main
struct feethacksApp: App {
    //create the ar manager
    @StateObject var arManager = ARManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(arManager: arManager)
        }
    }
}

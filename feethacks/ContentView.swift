//
//  ContentView.swift
//  feethacks
//
//  Created by Taylor Tam on 2/14/25.
//

import SwiftUI

enum AppMode {
    case welcome
    case ar
    case instructionsView
    case plyDisplay
}

struct ContentView: View {
    @State private var appMode = AppMode.welcome
    @ObservedObject var arManager: ARManager
    
    var body: some View {
        switch(appMode){
        case .welcome:
            WelcomeView(appMode: $appMode)
        case .instructionsView:
            InstructionsView(appMode: $appMode)
        case .ar:
            arView(arManager: arManager, appmode: $appMode)
        case .plyDisplay: 
            PLYSceneView(arManager: arManager, mode: $appMode)
        }
    }
}




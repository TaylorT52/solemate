//
//  PLYSceneView.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftUI
import SceneKit
import Metal
import MetalKit
import SceneKit
import ModelIO

struct PLYSceneView: View {
    @ObservedObject var arManager: ARManager
    @Binding var mode: AppMode
    @State private var scene: SCNScene? = nil
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if let scene = scene {
                PlySceneView(scene: scene)
                    .edgesIgnoringSafeArea(.all)
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
            } else {
                Text("Loading point cloud...")
            }
            Button() {
                mode = .welcome
            } label: {
                Image(systemName: "house")
            }
            .padding()
        } .task {
            do {
                let plyFile = PLYFile(pointCloud: arManager.pointCloud)
                let plyData = try await plyFile.export()
                let fileURL = try writePLYDataToTempFile(data: plyData)
                if let loadedScene = loadPLYScene(from: fileURL) {
                    scene = loadedScene
                } else {
                    errorMessage = "Failed to load scene from PLY."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // Helper functions to write data and load the scene
   func writePLYDataToTempFile(data: Data) throws -> URL {
       let tempDirectory = FileManager.default.temporaryDirectory
       let fileURL = tempDirectory.appendingPathComponent("exported.ply")
       try data.write(to: fileURL)
       return fileURL
   }
    
    func loadPLYScene(from fileURL: URL) -> SCNScene? {
        return SCNScene()
    }
}

struct PlySceneView: UIViewRepresentable {
    let scene: SCNScene

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.scene = scene
        scnView.backgroundColor = .black
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update view if necessary
    }
}

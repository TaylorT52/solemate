//
//  ArView.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftUI

struct arView: View {
    @ObservedObject var arManager: ARManager
    @Binding var appmode: AppMode
    
    var body: some View {
        ZStack(alignment: .bottom) {
            UIViewWrapper(view: arManager.sceneView).ignoresSafeArea()
            
            HStack(spacing: 30) {
                Button {
                    arManager.isCapturing.toggle()
                } label: {
                    Image(systemName: arManager.isCapturing ?
                                      "stop.circle.fill" :
                                      "play.circle.fill")
                }
                
                ShareLink(item: PLYFile(pointCloud: arManager.pointCloud),
                                        preview: SharePreview("exported.ply")) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                }
                
                Button() {
                    appmode = AppMode.plyDisplay
                } label: {
                    Image(systemName: "display")
                }
            }.foregroundStyle(.black, .white)
                .font(.system(size: 50))
                .padding(25)
        }
    }
}

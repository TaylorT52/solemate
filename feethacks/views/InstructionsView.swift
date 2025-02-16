//
//  InstructionsView.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftUI

struct InstructionsView: View {
    @Binding var appMode: AppMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack() {
            Spacer()
            VStack(){
                Text("AR Scan Instructions")
                    .font(.system(size: 25, weight: .bold))
                    .padding(.vertical)
                    .padding(.horizontal)
                VStack(alignment: .leading){
                    Text("1. Wear white socks!")
                        .padding(.vertical, 2)
                        .padding(.horizontal)
                    Text("2. Press 'play' to begin scanning, and 'stop' to halt")
                        .padding(.vertical, 2)
                        .padding(.horizontal)
                    Text("3. Scan the *just* the bottom of your foot, moving the camera up and down your foot for accuracy")
                        .padding(.vertical, 2)
                        .padding(.horizontal)
                }
            }
            .padding()
            
            Spacer()
            HStack() {
                Button {
                    appMode = .ar
                } label: {
                    Text("Scan")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding()
                        .frame(width: 200)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

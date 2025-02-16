//
//  WelcomeView.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftUI

struct WelcomeView: View {
    @Binding var appMode: AppMode
    @Environment(\.colorScheme) var colorScheme
   
    var body: some View {
        VStack {
            Spacer()
            Text("Solemate")
                .font(.system(size: 35, weight: .bold))
                .padding(.vertical)
            Text("Find your perfect shoe match")
                .padding(.vertical)

       Image("heart_foot") // Replace with your asset name
           .resizable() // Makes the image scalable
           .scaledToFit() // Ensures it maintains aspect ratio
           .frame(width: 300, height: 300) // Set desired size
        
            Button {
                appMode = .instructionsView
            } label: {
                Text("Create an AR Scan")
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
            
            Spacer()
        }
    }
}

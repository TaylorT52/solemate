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
                .font(.system(size: 35, weight: .bold, design: .rounded))
                .padding(.vertical)
            Text("Find your perfect shoe match")
                .padding(.vertical)
            Spacer()
            Button {
                appMode = AppMode.ar
            } label: {
                Text("Create an AR Scan")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black) // Ensure text is visible
                    .padding()
                    .frame(width: 200)
                    .background(colorScheme == .dark ? Color.black : Color.white) // Add a background
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2) // Outline border
                    )
            }
            Spacer()
        }
    }
}

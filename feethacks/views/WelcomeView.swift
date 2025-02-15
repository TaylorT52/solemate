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
   
    var body: some View {
        Button() {
            appMode = AppMode.ar
        } label: {
            Text("Turn on AR Scanning")
        }
    }
}

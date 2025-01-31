//
//  LoadingView.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/30/25.
//

import SwiftUI

// MARK: - LOADING VIEW
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(Color.blue, lineWidth: 5)
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                .onAppear { isAnimating = true }
            
            Text("Fetching photos...")
                .font(.headline)
                .padding(.top, 10)
        }
    }
}

//
//  DraggableImageView.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/26/25.
//


import SwiftUI

struct DraggableImageView: View {
    @State private var dragOffset = CGSize.zero // Tracks the drag gesture temporarily
    @State private var angle: Double = 0

    var body: some View {
        Image("magazine-back-cover") // Replace with your image name
            .resizable()
            .scaledToFit()
            .frame(width: 400, height: 400) // Adjust as needed
            .offset(x: dragOffset.width, y: 0) // Apply horizontal offset only
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Update offset with horizontal movement only
                        dragOffset.width = value.translation.width * 3
                        
                        // Calculate rotation angle based on horizontal swipe direction
                        angle = dragOffset.width/10 // Adjust divisor for sensitivity
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            dragOffset = .zero // Snap back to the center
                            angle = 0
                            UIImpactFeedbackGenerator(style: .light).impactOccurred() // Add haptic feedback
                        }
                    }
            )
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 0.0, y: 0, z: 0.001), // Diagonal rotation
                perspective: 0.8          // Adds a depth perspective
            )
    }
}

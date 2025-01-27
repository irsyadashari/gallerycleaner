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
    let image: UIImage // Pass a dynamic image
    let onSwipe: (Bool) -> Void // Callback to indicate swipe direction (true for right, false for left)

    var body: some View {
        Image(uiImage: image) // Replace with your image name
            .resizable()
            .scaledToFit()
            .frame(width: 400, height: 400) // Adjust as needed
            .offset(x: dragOffset.width, y: 0) // Apply horizontal offset only
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Update offset with horizontal movement only
                        dragOffset.width = value.translation.width 
                        
                        // Calculate rotation angle based on horizontal swipe direction
                        angle = dragOffset.width/10 // Adjust divisor for sensitivity
                    }
                    .onEnded { value in
                        if value.translation.width > 100 {
                            // Swipe right: Keep the photo
                            onSwipe(true)
                        } else if value.translation.width < -100 {
                            // Swipe left: Delete the photo
                            onSwipe(false)
                        }
                        
                        // Snap back to the center
                        withAnimation(.spring()) {
                            dragOffset = .zero
                            angle = 0
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

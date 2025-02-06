//
//  DraggableImageView.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/26/25.
//


import SwiftUI

struct DraggableImageView: View {
    @State private var dragOffset = CGSize.zero
    @State private var angle: Double = 0
    
    let image: UIImage
    let imageIndex: Int
    let onSwipe: (Bool) -> Void
    let swipeThreshold: CGFloat = 100
    let rotationSensitivity: Double = 10
    
    private let horizontalPadding: CGFloat = 32.0
    private let screenWidth = UIScreen.main.bounds.width - horizontalPadding
    private let screenHeight = UIScreen.main.bounds.height - 200
    let cornerRadius: CGFloat = 16 // Define the corner radius value
    
    var body: some View {
        if imageIndex == 0 {
            VStack {
                Text("Swipe right to keep, left to delete")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: screenHeight)
                    .cornerRadius(cornerRadius) // Add corner radius
                    .offset(x: dragOffset.width, y: 0)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset.width = value.translation.width
                                angle = dragOffset.width / rotationSensitivity
                            }
                            .onEnded { value in
                                if value.translation.width > swipeThreshold {
                                    onSwipe(true) // Swipe right
                                    triggerHapticFeedback()
                                } else if value.translation.width < -swipeThreshold {
                                    onSwipe(false) // Swipe left
                                    triggerHapticFeedback()
                                }
                                
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                    angle = 0
                                }
                            }
                    )
                    .rotation3DEffect(
                        .degrees(angle),
                        axis: (x: 0.0, y: 0, z: 0.001),
                        perspective: 0.8
                    )
                    .accessibilityLabel("Draggable Image")
                    .accessibilityHint("Swipe right to keep, swipe left to delete")
            }
        }
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

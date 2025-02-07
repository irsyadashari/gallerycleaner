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
    
    private let screenWidth = UIScreen.main.bounds.width - 64
    private let screenHeight = UIScreen.main.bounds.height - 200
    let cornerRadius: CGFloat = 16 // Define the corner radius value
    
    var body: some View {
        if imageIndex == 0 {
            VStack {
                Text("Swipe right to keep, left to delete")
                    .font(.headline)
                    .foregroundColor(AppColor.primaryText)
                    .padding(.bottom, 4)
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: screenHeight)
                    .cornerRadius(cornerRadius) // Add corner radius
                    .shadow(color: Color.black.opacity(0.6), radius: 20, x: -5, y: 5)
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
                                } else if value.translation.width < -swipeThreshold {
                                    onSwipe(false) // Swipe left
                                }
                                triggerHapticFeedback()
                                
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
                    .padding()
                    .accessibilityLabel("Draggable Image")
                    .accessibilityHint("Swipe right to keep, swipe left to delete")
            }
            .background(.clear)
        }
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

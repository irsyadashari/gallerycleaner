//
//  ContentView.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/14/25.
//

import SwiftUI
import Photos

// MARK: - VIEW
struct ContentView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @State private var backgroundColor: Color = AppColor.backgroundPrimary
    
    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut(duration: 1.0), value: backgroundColor)
            VStack {
                Spacer()
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.photoStack.isEmpty {
                    VStack {
                        Text("No more photos available!")
                            .font(.headline)
                            .padding()
                        Button("Reload Photos", action: viewModel.fetchMorePhotos)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                } else {
                    ZStack {
                        ForEach(viewModel.photoStack.indices.reversed(), id: \ .self) { index in
                            DraggableImageView(image: viewModel.photoStack[index].image, imageIndex: index) { isSwipeRight in
                                viewModel.handleSwipe(at: index, keep: isSwipeRight)
                                updateBackgroundColor(isSwipeRight: isSwipeRight)
                            }
                            .zIndex(Double(index))
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                Button("Delete All", action: viewModel.deletePendingPhotos)
                    .disabled(viewModel.photosToDelete.isEmpty)
                Spacer()
            }.background(.clear)
        }
    }
    
    private func updateBackgroundColor(isSwipeRight: Bool) {
        backgroundColor = isSwipeRight ? AppColor.greenKeep : AppColor.redDelete
        withAnimation(.smooth(duration: 1.0)) {
            backgroundColor = AppColor.backgroundPrimary
        }
    }
}

// MARK: - PREVIEW
#Preview {
    ContentView()
}

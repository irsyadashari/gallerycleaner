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
    
    var body: some View {
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
                        }
                        .zIndex(Double(index))
                    }
                }
                .padding()
            }
            Button("Delete All", action: viewModel.deletePendingPhotos)
                .disabled(viewModel.photosToDelete.isEmpty)
            Spacer()
        }
    }
}

// MARK: - PREVIEW
#Preview {
    ContentView()
}

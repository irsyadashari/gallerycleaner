//
//  ContentView.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/14/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    @State private var photoStack: [UIImage] = [] // Stack of images
    @State private var isLoading = true          // Loading state

    var body: some View {
        VStack {
            if photoStack.isEmpty && isLoading {
                ProgressView("Loading Photos...")
            } else if photoStack.isEmpty {
                Text("No more photos available!")
                    .font(.headline)
                    .padding()
            } else {
                ZStack {
                    ForEach(photoStack.indices.reversed(), id: \.self) { index in
                        Image(uiImage: photoStack[index])
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 400)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .offset(x: CGFloat(index) * 5, y: CGFloat(index) * 5) // Staggering effect
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            keepPhoto(at: index)
                                        } else if gesture.translation.width < -100 {
                                            deletePhoto(at: index)
                                        }
                                    }
                            )
                    }
                }
                .padding()
                .onChange(of: photoStack.count) { count in
                    if count <= 3 {
                        fetchMorePhotos()
                    }
                }
            }
        }
        .onAppear {
            requestPhotoLibraryAccess()
        }
    }
    
    // Request photo library access
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                fetchMorePhotos()
            } else {
                print("Photo library access denied")
                isLoading = false
            }
        }
    }
    
    // Handle keeping a photo
    func keepPhoto(at index: Int) {
        withAnimation {
            photoStack.remove(at: index)
        }
    }
    
    // Handle deleting a photo
    func deletePhoto(at index: Int) {
        withAnimation {
            photoStack.remove(at: index)
        }
    }
    
    // Fetch more photos from the library
    func fetchMorePhotos() {
        isLoading = true
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 10
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 400, height: 400)
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = false
        
        var newPhotos: [UIImage] = []
        
        assets.enumerateObjects { asset, _, _ in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    newPhotos.append(image)
                }
            }
        }
        
        DispatchQueue.main.async {
            photoStack.append(contentsOf: newPhotos)
            isLoading = false
        }
    }
}


#Preview {
    ContentView()
}

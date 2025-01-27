//
//  ContentView.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/14/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    @State private var photoStack: [Photo] = [] // Stack of images
    @State private var isLoading = true          // Loading state
    @State private var keptPhotos: [Photo] = [] // Photos swiped right but not displayed
    @State private var fetchLimit: Int = 10
    
    var body: some View {
        VStack {
            if photoStack.isEmpty && isLoading {
                ProgressView("Loading Photos...")
            } else if photoStack.isEmpty && !isLoading {
                VStack {
                    Text("No more photos available!")
                        .font(.headline)
                        .padding()
                    
                    Button(action: {
                        fetchMorePhotos()
                    }) {
                        Text("Reload Photos")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            } else {
                ZStack {
                    ForEach(photoStack.indices.reversed(), id: \.self) { index in
                        DraggableImageView(image: photoStack[index].image) { isSwipeRight in
                            handleSwipe(at: index, keep: isSwipeRight)
                        }
                        .zIndex(Double(index))
                    }
                }
                .padding()
                .onChange(of: photoStack.count) { count in
                    if count < 2 {
                        fetchMorePhotos()
                    }
                }
            }
        }
        .onAppear {
            requestPhotoLibraryAccess()
        }
    }
    
    func handleSwipe(at index: Int, keep: Bool) {
        // Extract the asset identifier for the swiped photo
        guard index < photoStack.count else { return }
        let photo = photoStack[index]
        
        withAnimation(.easeOut(duration: 0.2)) {
            // Safely remove the photo from the stack first
            let photo = photoStack.remove(at: index)
        }
        
        if keep {
            // Swipe Right: Keep the photo
            keepPhoto(photo)
        } else {
            // Swipe Left: Delete the photo
            deletePhoto(photo)
        }
    }
    
    // MARK: - Keep Photo Logic
    func keepPhoto(_ photo: Photo) {
        keptPhotos.append(photo)
        print("Photo kept.")
    }
    
    // MARK: - Delete Photo Logic
    func deletePhoto(_ photo: Photo) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photo.assetIdentifier], options: nil)
        guard let assetToDelete = fetchResult.firstObject else {
            print("Unable to fetch asset for deletion.")
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([assetToDelete] as NSArray)
        }) { success, error in
            if success {
                print("Photo successfully deleted.")
            } else if let error = error {
                print("Error deleting photo: \(error.localizedDescription)")
            }
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
    
    // Fetch more photos from the library
    func fetchMorePhotos() {
        isLoading = true
        
        // Fetch the assets
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = fetchLimit
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard assets.count > 0 else {
            DispatchQueue.main.async {
                isLoading = false
            }
            return
        }
        
        // Load images asynchronously
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 400, height: 400)
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true // Allow loading from iCloud
        requestOptions.resizeMode = .exact           // Ensure images are resized correctly
        
        var newPhotos: [Photo] = []
        let group = DispatchGroup() // To track loading completion
        
        let keptIdentifiers = keptPhotos.map { $0.assetIdentifier }
        let existingIdentifiers = photoStack.map { $0.assetIdentifier }
        
        assets.enumerateObjects { asset, _, _ in
            let assetIdentifier = asset.localIdentifier
            // Skip assets already in `photoStack` or `keptPhotos`
            guard !keptIdentifiers.contains(assetIdentifier),
                  !existingIdentifiers.contains(assetIdentifier) else { return }
            
            group.enter() // Start tracking this request
            
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                if let _image = image {
                    let photo = Photo(image: _image, assetIdentifier: asset.localIdentifier)
                    newPhotos.append(photo)
                }
                group.leave() // End tracking this request
            }
        }
        
        // When all image requests are complete
        group.notify(queue: .main) {
            photoStack.append(contentsOf: newPhotos)
            isLoading = false
        }
        
        self.fetchLimit += 10
    }
}


#Preview {
    ContentView()
}

struct Photo {
    let image: UIImage
    let assetIdentifier: String
}


extension UIImage {
    var assetIdentifier: String? {
        return self.accessibilityIdentifier
    }
    
    func setAssetIdentifier(_ identifier: String) -> UIImage {
        self.accessibilityIdentifier = identifier
        return self
    }
}

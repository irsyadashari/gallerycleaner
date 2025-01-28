//
//  ContentView.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/14/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    @State private var isLoading = true          // Loading state
    @State private var isFetching = false // Prevent simultaneous fetches
    @State private var photoStack: [Photo] = [] // Stack of images
    @State private var keptPhotos: [Photo] = [] // Photos swiped right but not displayed
    @State private var photosToDelete: [Photo] = []
    @State private var deletedPhotos: [Photo] = [] // Store asset identifiers of deleted photos
    @State private var fetchLimit: Int = 10
    
    private let screenWidth =  UIScreen.main.bounds.width
    private let screenHeight =  UIScreen.main.bounds.height - 200
    
    var body: some View {
        VStack {
            Spacer()
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
                        debounceFetchMorePhotos()
                    }
                }
            }
            Spacer()
            Button("Delete All") {
                deletePendingPhotos()
            }
            .disabled(photosToDelete.isEmpty) // Disable if there are no photos to delete

        } // VSTACK
        .onAppear {
            requestPhotoLibraryAccess()
        }
    }
    
    // Debounced fetch method
    func debounceFetchMorePhotos() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Debounce delay
            if photoStack.count < 2 && !isLoading {
                fetchMorePhotos()
            }
        }
    }
    
    func handleSwipe(at index: Int, keep: Bool) {
        // Extract the asset identifier for the swiped photo
        guard index < photoStack.count else { return }
        let photo = photoStack[index]
        
        withAnimation(.easeOut(duration: 0.2)) {
            // Safely remove the photo from the stack first
            photoStack.remove(at: index)
        }
        
        if keep { // Swipe Right: Keep the photo
            keepPhoto(photo)
        } else {  // Swipe Left: Delete the photo
            photosToDelete.append(photo) // Collect photos for deletion
            deletedPhotos.append(contentsOf: photosToDelete) // Track deleted photo
        }
    }
    
    // MARK: - Keep Photo Logic
    func keepPhoto(_ photo: Photo) {
        keptPhotos.append(photo)
        print("Photo kept.")
    }
    
    // Add this to delete photos in bulk
    func deletePendingPhotos() {
        let identifiers = photosToDelete.map { $0.assetIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(fetchResult)
        }) { success, error in
            if success {
                print("Photos successfully deleted.")
                photosToDelete.removeAll()
            } else if let error = error {
                print("Error deleting photos: \(error.localizedDescription)")
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
        guard !isFetching else { return }
        isLoading = true
        isFetching = true
        fetchLimit += 10
        
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
        
        let targetSize = CGSize(width: screenWidth, height: screenHeight)
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true // Allow loading from iCloud
        requestOptions.resizeMode = .exact           // Ensure images are resized correctly
        
        var newPhotos: [Photo] = []
        let group = DispatchGroup() // To track loading completion
        
        let keptIdentifiers = keptPhotos.map { $0.assetIdentifier }
        let existingIdentifiers = photoStack.map { $0.assetIdentifier }
        let deletedIdentifiers = deletedPhotos.map { $0.assetIdentifier }
        
        assets.enumerateObjects { asset, _, _ in
            let assetIdentifier = asset.localIdentifier
            // Skip assets already in `photoStack` or `keptPhotos` or "deletedPhotos"
            guard !deletedIdentifiers.contains(assetIdentifier),
                  !keptIdentifiers.contains(assetIdentifier),
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
            DispatchQueue.main.async {
                isLoading = false
                isFetching = false // Reset the flag
            }
        }
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

//
//  GalleryViewModel.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/30/25.
//

import SwiftUI
import Photos

// MARK: - VIEWMODEL
class GalleryViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var photoStack: [Photo] = []
    @Published var keptPhotos: [Photo] = []
    @Published var photosToDelete: [Photo] = []
    @Published var fetchLimit: Int = 10
    @Published var fetchThreshold: Int = 3
    
    private let imageManager = PHImageManager.default()
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height - 200
    
    init() {
        requestPhotoLibraryAccess()
    }
    
    func shouldFetchMorePhotos() -> Bool {
        return photoStack.count <= fetchThreshold && !isLoading
    }
    
    func handleSwipe(at index: Int, keep: Bool) {
        guard index < photoStack.count else { return }
        let photo = photoStack.remove(at: index)
        if keep {
            keptPhotos.append(photo)
        } else {
            photosToDelete.append(photo)
        }
        
        if shouldFetchMorePhotos() {
            fetchMorePhotos()
        }
    }
    
    func deletePendingPhotos() {
        let identifiers = photosToDelete.map { $0.assetIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(fetchResult)
        }) { [weak self] success, error in
            if success {
                DispatchQueue.main.async {
                    self?.photosToDelete.removeAll()
                }
            } else if let error = error {
                print("Error deleting photos: \(error.localizedDescription)")
            }
        }
    }
    
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    self?.fetchMorePhotos()
                } else {
                    self?.isLoading = false
                }
            }
        }
    }
    
    func fetchMorePhotos() {
        isLoading = true
        fetchLimit += 10
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = fetchLimit
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard assets.count > 0 else {
            isLoading = false
            return
        }
        
        let targetSize = CGSize(width: screenWidth, height: screenHeight)
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .opportunistic
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.resizeMode = .exact
        
        var newPhotos: [Photo] = []
        let group = DispatchGroup()
        let keptIdentifiers = keptPhotos.map { $0.assetIdentifier }
        let existingIdentifiers = photoStack.map { $0.assetIdentifier }
        let deletedIdentifiers = photosToDelete.map { $0.assetIdentifier }
        
        assets.enumerateObjects { asset, _, _ in
            let assetIdentifier = asset.localIdentifier
            guard !deletedIdentifiers.contains(assetIdentifier),
                  !keptIdentifiers.contains(assetIdentifier),
                  !existingIdentifiers.contains(assetIdentifier) else { return }
            
            group.enter()
            self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
                if let image = image {
                    let photo = Photo(image: image, assetIdentifier: assetIdentifier)
                    newPhotos.append(photo)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.photoStack.append(contentsOf: newPhotos)
            self.isLoading = false
        }
    }
}

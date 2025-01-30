//
//  Photo.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/30/25.
//

import Foundation
import UIKit

struct Photo: Identifiable {
    let id = UUID()
    let image: UIImage
    let assetIdentifier: String
}

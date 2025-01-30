//
//  UIImage+Ext.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 1/30/25.
//

import UIKit

extension UIImage {
    var assetIdentifier: String? {
        return self.accessibilityIdentifier
    }
    
    func setAssetIdentifier(_ identifier: String) -> UIImage {
        self.accessibilityIdentifier = identifier
        return self
    }
}

//
//  Color+Ext.swift
//  GalleryCleaner
//
//  Created by Muh Irsyad Ashari on 2/6/25.
//

import SwiftUI

extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

struct AppColor {
    static let primaryText = Color(hex: "#2d435b")
    static let greenKeep = Color(hex: "#00ff00")
    static let redDelete = Color(hex: "#ff0000")
    static let backgroundPrimary = Color(hex: "#fcf3c8")
}

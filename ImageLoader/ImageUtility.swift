//
//  ImageResizer.swift
//  ImageLoader
//
//  Created by Ankur Arya on 24/02/19.
//  Copyright © 2019 Ankur Arya. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    /// Get the scaled image.
    ///
    /// - Parameter targetSize: size to which image is to be scaled.
    /// - Returns: scaled image object.
    func getScaledImage(to targetSize: CGSize) -> UIImage? {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /// Get Image data size.
    ///
    /// - Returns: image data size in Kb.
    func imageDataSize() -> Int {
        return (self.jpegData(compressionQuality: 1)?.count ?? 0) / 1000 // Size in Kb
    }
}

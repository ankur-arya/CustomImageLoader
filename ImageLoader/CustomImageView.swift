//
//  CustomImageView.swift
//  ImageLoader
//
//  Created by Ankur Arya on 23/02/19.
//  Copyright © 2019 Ankur Arya. All rights reserved.
//

import UIKit

@IBDesignable

/// Generic image view class that provides circular loader.
class CustomImageView: UIImageView {
    
    private var gradientColor: UIColor?
    var placeholder: UIImage? {
        didSet {
            self.image = placeholder
        }
    }
    var gradientColors: [UIColor]? {
        didSet {
            gradientColor = createGradient(with: gradientColors)
        }
    }
    
    override func prepareForInterfaceBuilder() {
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupView()
    }
    
    private func setupView() {
        self.layer.cornerRadius = self.bounds.width/2
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 2
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
    }
    
    /// Create gradient color from array of colors.
    ///
    /// - Parameter colors: array of UIColor.
    /// - Returns: gradient color.
    private func createGradient(with colors: [UIColor]?) -> UIColor {
        // create the background layer that will hold the gradient
        let backgroundGradientLayer = CAGradientLayer()
        backgroundGradientLayer.frame = frame
        backgroundGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.0, y: 1)
        
        // we create an array of CG colors from out UIColor array
        let cgColors = colors?.map({$0.cgColor})
        backgroundGradientLayer.colors = cgColors
        layer.addSublayer(backgroundGradientLayer)
        
        UIGraphicsBeginImageContext(backgroundGradientLayer.bounds.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIColor.black
        }
        backgroundGradientLayer.render(in: context)
        let backgroundColorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        backgroundGradientLayer.removeFromSuperlayer()
        
        guard let bgImage = backgroundColorImage else {
            return UIColor.black
        }
        return UIColor(patternImage: bgImage)
    }
    
    /// Add loader on image view.
    ///
    /// - Parameters:
    ///   - startAngle: start angle in radians.
    ///   - endAngle: end angle in radians.
    internal func addCircularLoader(startAngle: CGFloat, endAngle: CGFloat) {
        let loaderLayer = CAShapeLayer()
        let path = UIBezierPath(arcCenter: CGPoint(x: self.bounds.height/2, y: self.bounds.width/2), radius: (self.frame.size.height/2), startAngle: startAngle, endAngle: endAngle, clockwise: true)
        loaderLayer.path = path.cgPath
        loaderLayer.strokeColor = gradientColor?.cgColor ?? UIColor.blue.cgColor
        loaderLayer.fillColor = UIColor.clear.cgColor
        loaderLayer.lineWidth = 10
        loaderLayer.lineCap = .round
        self.layer.addSublayer(loaderLayer)
    }
    
    /// Remove loader layers from image view layer.
    internal func removeLoader() {
        self.layer.sublayers?.removeAll(keepingCapacity: false)
    }
}

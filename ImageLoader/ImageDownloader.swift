//
//  DownloadImage.swift
//  ImageLoader
//
//  Created by Ankur Arya on 25/02/19.
//  Copyright © 2019 Ankur Arya. All rights reserved.
//

import UIKit
import RxSwift

protocol DownloadImageProtocol {
    
    /// Get image from url that is scaled to provided size.
    ///
    /// - Parameters:
    ///   - url: image url.
    ///   - size: target size for scalling.
    /// - Returns: observable of response data.
    func getImage(url: URL, size: CGSize) -> Observable<ResponseData>?
}

class ImageDownloader: DownloadImageProtocol {
    var repo: ImageRepo
    var cache: ImageCache
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - repo: image repo interface
    ///   - cache: image cache interface.
    init(repo: ImageRepo, cache: ImageCache) {
        self.repo = repo
        self.cache = cache
    }
    
    /// Get image from url that is scaled to provided size.
    ///
    /// - Parameters:
    ///   - url: image url.
    ///   - size: target size for scalling.
    /// - Returns: observable of response data.
    func getImage(url: URL, size: CGSize) -> Observable<ResponseData>? {
        
        if let imageFromCache = self.cache.fetchImage(from: url.getPath()) {
            return Observable<ResponseData>.create({ observer in
                let responseData = ResponseData(totalBytesWritten: 1, totalBytesExpectedToWrite: 1, image: imageFromCache)
                observer.onNext(responseData)
                observer.onCompleted()
                return Disposables.create {
                }
            })
        } else {
            return self.repo.downloadImage(from: url).map({ ( data ) -> ResponseData in
                let scaledImage = data.image?.getScaledImage(to: size)
                // cache this scaled image
                if scaledImage != nil {
                    self.cache.saveImage(image: scaledImage!, to: url.getPath())
                }
                return ResponseData(totalBytesWritten: Int64(data.totalBytesWritten), totalBytesExpectedToWrite: Int64(data.totalBytesExpectedToWrite), image: scaledImage)
            })
        }
    }
}

extension URL {
    /// Get path from url
    ///
    /// - Returns: string with special characters removed from url path.
    func getPath() -> String {
        var path = self.path
        path = path.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        return "\(path).jpg"
    }
}

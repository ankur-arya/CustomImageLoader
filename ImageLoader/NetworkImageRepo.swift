//
//  ImageDownloader.swift
//  ImageLoader
//
//  Created by Ankur Arya on 23/02/19.
//  Copyright © 2019 Ankur Arya. All rights reserved.
//

import UIKit
import RxSwift

/// Struct for response data.
struct ResponseData {
    var totalBytesWritten: Int64
    var totalBytesExpectedToWrite: Int64
    var image: UIImage?
}

/// Image Repo for downloading image from URL.
protocol ImageRepo {
    
    /// Download image from url.
    ///
    /// - Parameter url: image url.
    /// - Returns: observable with response data.
    func downloadImage(from url: URL) -> Observable<ResponseData>
}

class NetworkImageRepo: NSObject, URLSessionDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate, ImageRepo {
    
    var publisher: PublishSubject<ResponseData>?
    
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        return formatter
    }()
    
    /// Download image from url.
    ///
    /// - Parameter url: image url.
    /// - Returns: observable with response data.
    public func downloadImage(from url: URL) -> Observable<ResponseData> {
        publisher = PublishSubject<ResponseData>()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 300
        if #available(iOS 11, *) {
            config.waitsForConnectivity = true
        }
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        session.downloadTask(with: url).resume()
        return publisher! //This will never be nil as we have already initilized the object hence the `!`.
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let data = ResponseData(totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite, image: nil)
        publisher?.onNext(data)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let data = try? Data(contentsOf: location), let image = UIImage(data: data) {
            let data = ResponseData(totalBytesWritten: Int64(data.count), totalBytesExpectedToWrite: Int64(data.count), image: image)
            publisher?.onNext(data)
            publisher?.onCompleted()
        } else {
            publisher?.onError(RxError.noElements)
        }
    }
    
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        publisher?.onError(RxError.timeout)
    }
}

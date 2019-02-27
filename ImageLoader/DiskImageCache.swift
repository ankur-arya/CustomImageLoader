//
//  DiskImageCache.swift
//  ImageLoader
//
//  Created by Ankur Arya on 25/02/19.
//  Copyright © 2019 Ankur Arya. All rights reserved.
//

import UIKit

protocol ImageCache {
    
    /// Save image to cache.
    ///
    /// - Parameters:
    ///   - image: image object.
    ///   - path: path at which image is to be saved.
    func saveImage(image: UIImage, to path: String)
    
    /// Get image from cache.
    ///
    /// - Parameter path: path from which image is to be fetched.
    /// - Returns: image object.
    func fetchImage(from path: String) -> UIImage?
}

struct CacheInfo: Codable {
    var totalImageCapacity: Int
    var availableImageCapacity: Int
    var totalDiskCapacity: Int
    var availableDiskCapacity: Int
    var cachedImages:[String]?
}

enum CacheKeys: String {
    case totalImageCapacity = "totalImageCapacity"
    case availableImageCapacity = "availableImageCapacity"
    case totalDiskCapacity = "totalDiskCapacity"
    case availableDiskCapacity = "availableDiskCapacity"
    case cachedImages = "cachedImages"
}

/// Image cache class which conforms to ImageCache protocol.
class DiskImageCache: ImageCache {
    
    var cacheInfo: CacheInfo? {
        get {
            return readDataFromCachePlist()
        }
    }
    
    var cacheDiskPath: URL {
        get {
            let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            return documentDirectory.appendingPathComponent("CacheInfo.plist")
        }
    }
    
    /// Initilazier
    ///
    /// - Parameters:
    ///   - imageCapacity: number of max images that can be saved in cache.
    ///   - diskCapacity: max disk capacity size in Kb.
    init(imageCapacity: Int, diskCapacity: Int) {
        
        // Write Plist to Document Directory if already not written.
        if !FileManager.default.fileExists(atPath: cacheDiskPath.path) {
            guard let bundlePath = Bundle.main.path(forResource: "CacheInfo", ofType: "plist") else { return }
            guard let dict = NSMutableDictionary(contentsOfFile: bundlePath) else { return }
            dict.write(to: cacheDiskPath, atomically: true)
            writeDataToCachePlist(data: imageCapacity, key: .totalImageCapacity)
            writeDataToCachePlist(data: diskCapacity, key: .totalDiskCapacity)
            writeDataToCachePlist(data: imageCapacity, key: .availableImageCapacity)
            writeDataToCachePlist(data: diskCapacity, key: .availableDiskCapacity)
        }
    }
    
    /// Save image to cache.
    ///
    /// - Parameters:
    ///   - image: image object.
    ///   - path: path at which image is to be saved.
    func saveImage(image: UIImage, to path: String) {
        guard let cacheInfo = self.cacheInfo else {return}
        guard image.imageDataSize() < cacheInfo.totalDiskCapacity else {
            // Throw error for the caller to catch.
            print("Image is to large to save in cache.")
            return
        }
        
        if !canWrite(newImage: image) {
            removeExcessData(image: image, path: path)
        }
        
        writeImageToDisk(image, path: path)
        writeDataToCachePlist(data: path, key: .cachedImages)
        
        // Update cache availablity
        let newImageAvailability = cacheInfo.availableImageCapacity - 1
        writeDataToCachePlist(data: newImageAvailability, key: .availableImageCapacity)
        
        // Update disk space availablity
        let newDiskAvailability = cacheInfo.availableDiskCapacity - image.imageDataSize()
        writeDataToCachePlist(data: newDiskAvailability, key: .availableDiskCapacity)
        
    }
    
    /// Get image from cache.
    ///
    /// - Parameter path: path from which image is to be fetched.
    /// - Returns: image object.
    func fetchImage(from path: String) -> UIImage? {
        let image = readImageFromDisk(path: path)
        // Update image array for LRU
        if image != nil {
            deleteDataFromCachePlist(path: path, key: .cachedImages)
            writeDataToCachePlist(data: path, key: .cachedImages)
        }
        
        return image
    }
    
    // MARK: Plist CURD functions.
    
    /// Read cache plist data from document directory.
    ///
    /// - Returns: CacheInfo object.
    private func readDataFromCachePlist() -> CacheInfo? {
        let jsonDecoder = JSONDecoder()
        do {
            guard let dict = NSDictionary(contentsOfFile: cacheDiskPath.path) else { return nil }
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            let result = try jsonDecoder.decode(CacheInfo.self, from: jsonData)
            return result
            
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    /// Write data to cache plist.
    ///
    /// - Parameters:
    ///   - data: data for cache plist.
    ///   - key: key for which data needs to be written.
    private func writeDataToCachePlist(data: Any, key: CacheKeys) {
        guard let dict = NSMutableDictionary(contentsOfFile: cacheDiskPath.path) else { return }
        if key == .cachedImages {
            if var array: Array<String> = dict[key.rawValue] as? Array<String>, let filePath = data as? String {
                array.insert(filePath, at: 0)
                dict.setValue(array, forKey: key.rawValue)
            }
        } else {
            dict.setValue(data, forKey: key.rawValue)
        }
        dict.write(toFile: cacheDiskPath.path, atomically: false)
    }
    
    /// Delete data from cache plist.
    ///
    /// - Parameters:
    ///   - path: path for image.
    ///   - key: key for which data needs to be removed.
    private func deleteDataFromCachePlist(path: String, key: CacheKeys) {
        guard let dict = NSMutableDictionary(contentsOfFile: cacheDiskPath.path) else { return }
        if key == .cachedImages {
            if var array: Array<String> = dict[key.rawValue] as? Array<String> {
                if let indexOfObject = array.firstIndex(of: path) {
                    array.remove(at: indexOfObject)
                }
                dict.setValue(array, forKey: key.rawValue)
            }
        } else {
            dict.setValue(nil, forKey: key.rawValue)
        }
        dict.write(toFile: cacheDiskPath.path, atomically: false)
    }
    
    // MARK: Disk CURD functions.
    
    /// Write image data to document directory.
    ///
    /// - Parameters:
    ///   - image: image data.
    ///   - path: path of image.
    private func writeImageToDisk(_ image: UIImage, path: String) {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(path)
            print(fileURL)
            if let imageData = image.jpegData(compressionQuality: 1) {
                try imageData.write(to: fileURL)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Read image data from document directory.
    ///
    /// - Parameter path: path of image.
    /// - Returns: image object.
    private func readImageFromDisk(path: String) -> UIImage? {
        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let filePath = documentsURL.appendingPathComponent(path).path
            return UIImage(contentsOfFile: filePath)
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    /// Remove image data from document directory.
    ///
    /// - Parameter path: path of image.
    private func removeImageFromDisk(path: String) {
        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let filePath = documentsURL.appendingPathComponent(path).path
            if FileManager.default.fileExists(atPath: filePath) {
                try? FileManager.default.removeItem(atPath: filePath)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Remove excess cache data from Document directory.
    ///
    /// - Parameters:
    ///   - image: image object.
    ///   - path: file path.
    private func removeExcessData(image: UIImage, path: String) {
        // Delete LRU image
        var imageDataSize = 0
        if let lruPath = cacheInfo?.cachedImages?.last {
            imageDataSize = fetchImage(from: lruPath)?.imageDataSize() ?? 0
            removeImageFromDisk(path: lruPath)
            deleteDataFromCachePlist(path: lruPath, key: .cachedImages)
            
            // Update image availablity
            let newImageAvailability = (cacheInfo?.availableImageCapacity ?? 0) + 1
            writeDataToCachePlist(data: newImageAvailability, key: .availableImageCapacity)
            
            // Update disk availablity
            let newDiskAvailability = (cacheInfo?.availableDiskCapacity ?? 0) + imageDataSize
            writeDataToCachePlist(data: newDiskAvailability, key: .availableDiskCapacity)
        }
        
        if !canWrite(newImage: image) {
            removeExcessData(image: image, path: path)
        } else {
            saveImage(image: image, to: path)
        }
    }
    
    /// Check if image data can be written to cache.
    ///
    /// - Parameter newImage: image object.
    /// - Returns: true/false based on cache availability.
    private func canWrite(newImage: UIImage) -> Bool {
        guard let cacheInfo = self.cacheInfo else {return false}
        let canWrite = cacheInfo.availableImageCapacity > 0 && cacheInfo.availableDiskCapacity > newImage.imageDataSize()
        return canWrite
    }
    
}

//
//  ViewController.swift
//  ImageLoader
//
//  Created by Ankur Arya on 22/02/19.
//  Copyright © 2019 Ankur Arya. All rights reserved.
//

import UIKit
import RxSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: CustomImageView!
    @IBOutlet weak var nextButton: UIButton!
    
    var imageDownloader:DownloadImageProtocol?
    let disposeBag = CompositeDisposable()
    
    
    /// Data Source for images.
    let imagesURLArray = ["https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_1280.jpg", "https://cdn.pixabay.com/photo/2016/03/28/12/35/cat-1285634_1280.png", "https://cdn.pixabay.com/photo/2014/11/30/14/11/kitty-551554_1280.jpg", "https://cdn.pixabay.com/photo/2017/11/14/13/06/kitty-2948404_1280.jpg", "https://cdn.pixabay.com/photo/2015/04/23/21/59/tree-736877_1280.jpg", "https://cdn.pixabay.com/photo/2015/05/22/05/52/cat-778315_1280.jpg", "https://cdn.pixabay.com/photo/2017/04/30/18/33/cat-2273598_1280.jpg", "https://cdn.pixabay.com/photo/2014/05/07/06/44/animal-339400_1280.jpg", "https://cdn.pixabay.com/photo/2017/07/25/01/22/cat-2536662_1280.jpg", "https://cdn.pixabay.com/photo/2015/11/16/22/14/cat-1046544_1280.jpg", "https://cdn.pixabay.com/photo/2015/11/15/22/09/cat-1044914_1280.jpg"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Avatar Loader"
        setupView()
    }
    
    /// Setup view elements and cache.
    private func setupView() {
        let cache = DiskImageCache(imageCapacity: 5, diskCapacity: 1000)
        imageDownloader = ImageDownloader(repo: NetworkImageRepo(), cache: cache)
        
        imageView.placeholder = UIImage(named: "Placeholder")
        imageView.gradientColors = [UIColor.red, UIColor.yellow]
        
        nextButton.layer.borderColor = UIColor.black.cgColor
        nextButton.layer.cornerRadius = 5
        nextButton.layer.borderWidth = 2
        
        loadImage()
    }
    
    @IBAction func loaderButton(_ sender: Any) {
        loadImage()
    }
    
    /// Load image.
    private func loadImage() {
        imageView.placeholder = UIImage(named: "Placeholder")
        
        // get random url from image datasource.
        if let url = URL(string:imagesURLArray.randomElement() ?? "") {
            nextButton.isEnabled = false
            loadImage(url: url)
        }
    }
    
    /// Load image from url.
    ///
    /// - Parameter url: image url.
    fileprivate func loadImage(url: URL) {
        var startAngle: CGFloat = -CGFloat.pi/2
        var endAngle: CGFloat = -CGFloat.pi/2.1
        self.imageView.addCircularLoader(startAngle: startAngle, endAngle: endAngle)
        
        let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        if let disposable = imageDownloader?.getImage(url: url, size: imageView.bounds.size)?.subscribeOn(backgroundScheduler)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (data) in
                guard let weakSelf = self else { return }
                weakSelf.imageView.addCircularLoader(startAngle: startAngle, endAngle: endAngle)
                startAngle = endAngle
                endAngle = (CGFloat(data.totalBytesWritten)/CGFloat(data.totalBytesExpectedToWrite)) * 2 * CGFloat.pi
                if data.image != nil {
                    weakSelf.imageView.image = data.image
                }
                }, onError: { [weak self] (error) in
                    guard let weakSelf = self else { return }
                    weakSelf.cleanUpUI()
                    weakSelf.showError(with: error)
                }, onCompleted: { [weak self] in
                    guard let weakSelf = self else { return }
                    weakSelf.cleanUpUI()
            }) {
            let _ = disposeBag.insert(disposable)
        }
    }
    
    
    /// Remove loader from imageview and enable next button.
    func cleanUpUI() {
        self.imageView.removeLoader()
        self.nextButton.isEnabled = true
    }
    
    /// To show alert on view controller if an api throws an error.
    ///
    /// - Parameter error: error object from network call.
    internal func showError(with error: Error) {
        let alert = UIAlertController(title: "Error!!!", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    deinit {
        disposeBag.dispose()
    }
}

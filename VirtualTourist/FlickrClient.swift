//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 02.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient: NSObject {
    
    //
    // MARK: Constants (Statics)
    //
    
    static let sharedInstance = FlickrClient()
    
    //
    // MARK: Constants (Special)
    //
    
    let client = RequestClient.sharedInstance
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //
    // MARK: Constants (Normal)
    //
    
    let debugMode: Bool = true
    let session = URLSession.shared
    let maxAllowedPages = 2500
    let maxDownloadTimeout = 30.0
    let photoPreviewDownscale: CGFloat = 0.5
    let photoPreviewQuality: CGFloat = 0.65
    
    //
    // MARK: Variables
    //
    
    var photo:Photo?
    
    func setImageQueue(_ numberOfImages: Int, _ targetPin: Pin) {
    
        appDelegate.photoQueue.removeAll()
        appDelegate.photoQueueImagesDownloaded = 0
        
        for index in 0 ... numberOfImages - 1  {
            appDelegate.photoQueue.append(PhotoQueueItem(
                metaHash: "\(index)".md5(),
                metaQueueIndex: index,
                metaQueueCreatedAt: Date(),
                metaQueueUpdatedAt: Date(),
                metaLocationHash: targetPin.metaHash,
                metaDownloadAsCellProcessed: false,
                metaDownloadCompleted: false,
                metaDownloadMsg: "download photo #\(index)",
                metaDataSizeRaw: 0.0,
                metaDataSizeConverted: 0.0,
                imageSourceURL: nil,
                imageJPEGRaw: nil,
                imageJPEGConverted: nil,
                imageCellSelected: false,
                photo: nil
            ))
        }
    }
    
    func getImagesByMapPin (
       _ targetPin: Pin,
       _ numberOfPhotos: Int?,
       _ completionHandlerForFetchFlickrImages: @escaping (_ success: Bool?, _ error: String?) -> Void) {
        
        var _numberOfPhotos = appDelegate.pinMaxNumberOfPhotos
        if   numberOfPhotos != nil {
            _numberOfPhotos = numberOfPhotos!
        }
        
        let _requestParams = [
    
            FlickrClientConstants.apiBaseParams._format: FlickrClientConstants.apiConfig._format,
            FlickrClientConstants.apiBaseParams._page: NSString(format: "%d", getRandomPageFromPersistedPin(targetPin)) as String,
            FlickrClientConstants.apiBaseParams._perPage: NSString(format: "%d", _numberOfPhotos) as String,
            FlickrClientConstants.apiBaseParams._noJSONCallback: "1",
            FlickrClientConstants.apiBaseParams._apiKey: FlickrClientConstants.apiConfig._pubKey,
            FlickrClientConstants.apiBaseParams._method: FlickrClientConstants.apiSearchParams.methodName,
            
            FlickrClientConstants.apiSearchParams.bbox: getBoundingBoxAsString(targetPin),
            
            FlickrClientConstants.apiSearchParams.safeSearch: "1",
            FlickrClientConstants.apiSearchParams.accuracy: "1",
            FlickrClientConstants.apiSearchParams.contentType: "1",
            FlickrClientConstants.apiSearchParams.media: "photos",
            FlickrClientConstants.apiSearchParams.extras: "url_m"
            
        ] as [String : AnyObject]
        
        client.get(FlickrClientConstants.apiConfig._url, headers: [:], parameters: _requestParams, bodyParameters: [:])
        {
            (data, error) in
            
            if (error != nil) {
                
                completionHandlerForFetchFlickrImages(false, "Oops! Request could not be handled: \(String(describing: error!))")
                
            } else {
            
                var UIImageOrigin: UIImage?
                var UIImagePreview: UIImage?
                var sizeImageOrigin: Double = 0.0
                var sizeImagePreview: Double = 0.0

                // try to handle json result by binding specific keys (photos, photo and pages)
                if  let photoResultDictionary = data?.value(forKey: "photos") as? [String: AnyObject],
                    let photoResultArray = photoResultDictionary["photo"] as? [[String: AnyObject]],
                    let numOfPages = photoResultDictionary["pages"] as? UInt32 {
                    
                    // update targetPin with current request metadata for 'numOfPages'
                    targetPin.metaNumOfPages = numOfPages as NSNumber
                    self.setPinNumberOfPagesByReference(targetPin) { (updatedPin, success, error) in
                        if (error != nil) { completionHandlerForFetchFlickrImages(false, error); return }
                    }
                    
                    // start dispatched download process, including image processsing and coreData/
                    // coreStock handling of api fetch resulting photos
                    DispatchQueue.main.async(execute: {
                        
                        // calculate the maximum number of photos available for this location
                        let _imageExpectedCount = photoResultArray.count
                        
                        // prepare imageQueue stack
                        self.setImageQueue(_imageExpectedCount, targetPin)
                        
                        // loop through image urls and start photo processing
                        for (imageLoopIndex, photoDictionary) in photoResultArray.enumerated() {
                        
                            let _imageUrl = photoDictionary["url_m"] as! String
                            
                            var queueItem = self.appDelegate.photoQueue[imageLoopIndex]
                            
                            // primary downloading process
                            
                            self.handlePhotoByFlickrUrl(_imageUrl, _imageExpectedCount, imageLoopIndex, targetPin)
                            {
                                (_photo, imgDataOrigin, imgDataPreview, success, error) in
                                
                                if (error != nil) {
                                    
                                    // update queue media item (for failure)
                                    queueItem._metaDownloadCompleted = false
                                    queueItem._metaDownloadAsCellProcessed = false
                                    queueItem._metaDownloadMsg = error?.description
                                    queueItem._metaQueueUpdatedAt = Date()
                                    
                                    completionHandlerForFetchFlickrImages(false, "Oops! Download could not be handled: \(error!)")
                                    
                                    self.appDelegate.photoQueue[imageLoopIndex] = queueItem
                                    
                                } else {
                                    
                                    // update queue media item (for success)
                                    let queueMsg = "-> src=\(imgDataOrigin!), min=\(imgDataPreview!), \(imageLoopIndex + 1) of \(_imageExpectedCount)"
                                    
                                    if let _imageOrigin = _photo!.imageRaw {
                                        UIImageOrigin = UIImage(data: _imageOrigin, scale: 1.0)
                                        sizeImageOrigin = Double(_imageOrigin.count) / 1024.0
                                    }
                                    
                                    if let _imagePreview = _photo!.imagePreview {
                                        UIImagePreview = UIImage(data: _imagePreview, scale: 1.0)
                                        sizeImagePreview = Double(_imagePreview.count) / 1024.0
                                    }
                                    
                                    queueItem._metaDownloadCompleted = true
                                    queueItem._metaDownloadAsCellProcessed = false
                                    queueItem._metaQueueUpdatedAt = Date()
                                    queueItem._metaHash = _imageUrl.md5()
                                    queueItem._metaDataSizeConverted = sizeImagePreview
                                    queueItem._metaDataSizeRaw = sizeImageOrigin
                                    queueItem._metaDownloadMsg = queueMsg
                                    queueItem._imageSourceURL = _imageUrl
                                    queueItem._imageJPEGRaw = UIImageOrigin
                                    queueItem._imageJPEGConverted = UIImagePreview
                                    queueItem._photo = _photo
                                    
                                    completionHandlerForFetchFlickrImages(true, nil)
                                    
                                    self.appDelegate.photoQueue[imageLoopIndex] = queueItem
                                    
                                }
                            }
                        }
                    })
                }
            }
        }
    }
}

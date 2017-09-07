//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 02.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import Kingfisher
import CoreStore
import CryptoSwift

class FlickrClient: NSObject {
    
    //
    // MARK: Constants (Statics)
    //
    
    static let sharedInstance = FlickrClient()
    
    //
    // MARK: Constants (Normal)
    //
    
    let debugMode: Bool = true
    let session = URLSession.shared
    let client = RequestClient.sharedInstance
    let maxAllowedPages = 2500
    let maxPhotesEachPage = 20
    let maxDownloadTimeout = 30.0
    
    var photo:Photo?
    
    //
    // MARK: Constants (API)
    //
    
    struct apiConfig {
        
        static let _url: String = "https://api.flickr.com/services/rest/"
        static let _pubKey: String = "945c147f91129f6f5a795b8a58f15852"
        static let _format: String = "json"
        static let _version: UInt8 = 1
    }
    
    struct apiBaseParams {
        
        static let _format = "format"
        static let _page = "page"
        static let _perPage = "per_page"
        static let _apiKey = "api_key"
        static let _method = "method"
        static let _noJSONCallback = "nojsoncallback"
    }
    
    struct apiSearchParams {
        
        static let methodName = "flickr.photos.search"
        static let accuracy = "accuracy"
        static let contentType = "content_type"
        static let media = "media"
        static let extras = "extras"
        static let bbox = "bbox"
        static let sort = "sort"
        static let safeSearch = "safe_search"
    }
    
    struct apiSearchBBoxParams {
        
        static let _bbHalfWidth = 1.0
        static let _bbHalfHeight = 1.0
        static let _latMin = -90.0
        static let _latMax = 90.0
        static let _lonMin = -180.0
        static let _lonMax = 180.0
    }
    
    func getDownloadedImageForPhotoUrl(
       _ imageUrl: String,
       _ completionHandlerForDowloadedImage: @escaping (_ rawImage: UIImage?, _ success: Bool?, _ error: String?) -> Void) {
    
        ImageDownloader.default.downloadTimeout = maxDownloadTimeout
        ImageDownloader.default.downloadImage(with: URL(string: imageUrl)!, options: [], progressBlock: nil)
        {
            (rawImage, error, url, data) in
            
            if (error != nil) {
                
                completionHandlerForDowloadedImage(nil, false, "\(String(describing: error!))")
                
            } else {
                
                completionHandlerForDowloadedImage(rawImage, true, nil)
            }
        }
    }
    
    func handlePhotoByFlickrUrl (
       _ mediaUrl: String,
       _ completionHandlerForPhotoProcessor: @escaping (_ imgDataOrigin: Data?, _ imgDataPreview: Data?, _ success: Bool?, _ error: String?) -> Void) {
    
        self.getDownloadedImageForPhotoUrl(mediaUrl) { (rawImage, success, error) in
            
            if (error != nil) {
                completionHandlerForPhotoProcessor(nil, nil, false, error)
                
            } else {
                
                // prepare origin image
                guard let imageOrigin = UIImageJPEGRepresentation(rawImage!, 1) else {
                    completionHandlerForPhotoProcessor(nil, nil, false, error); return
                }
                
                // prepare thumbnail version of primary image (65% compression, 50% downscale)
                guard let imagePreview = UIImageJPEGRepresentation(rawImage!.resized(withPercentage: 0.5)!, 0.65) else {
                    completionHandlerForPhotoProcessor(nil, nil, false, error); return
                }
                
                CoreStore.perform(
                    
                    asynchronous: { (transaction) -> Photo? in
                        
                        self.photo = transaction.create(Into<Photo>())
                        self.photo!.imageSourceURL = mediaUrl
                        self.photo!.imageHash = mediaUrl.md5()
                        self.photo!.imageRaw = imageOrigin
                        self.photo!.imagePreview = imagePreview
                        
                        return self.photo!
                        
                    },  success: { (transactionPhoto) in
                    
                        self.photo = CoreStore.fetchExisting(transactionPhoto!)!
                        
                        completionHandlerForPhotoProcessor(imageOrigin, imagePreview, true, nil)
                        
                    },  failure: { (error) in
                    
                        if self.debugMode == true { print ("--- photo object processing/persistence failed ---") }
                    
                        return
                    }
                )
            }
        }
    }

    func getSampleImages (
       _ targetPin: Pin,
       _ completionHandlerForSampleImages: @escaping (_ success: Bool?, _ error: String?) -> Void) {
    
        let _requestParams = [
    
            apiBaseParams._format: apiConfig._format,
            apiBaseParams._page: NSString(format: "%d", getRandomPageFromPersistedPin(targetPin)) as String,
            apiBaseParams._perPage: NSString(format: "%d", maxPhotesEachPage) as String,
            apiBaseParams._noJSONCallback: "1",
            apiBaseParams._apiKey: apiConfig._pubKey,
            apiBaseParams._method: apiSearchParams.methodName,
            
            apiSearchParams.bbox: getBoundingBoxAsString(targetPin),
            
            apiSearchParams.safeSearch: "1",
            apiSearchParams.accuracy: "1",
            apiSearchParams.contentType: "1",
            apiSearchParams.media: "photos",
            apiSearchParams.extras: "url_m"
            
        ] as [String : AnyObject]
        
        client.get(apiConfig._url, headers: [:], parameters: _requestParams, bodyParameters: [:])
        {
            (data, error) in
            
            if (error != nil) {
                
                completionHandlerForSampleImages(false, "Oops! Request could not be handled: \(String(describing: error!))")
                
            } else {
            
                // try to handle json result by binding specific keys (photos, photo and pages)
                if  let photoResultDictionary = data?.value(forKey: "photos") as? [String: AnyObject],
                    let photoResultArray = photoResultDictionary["photo"] as? [[String: AnyObject]],
                    let numOfPages = photoResultDictionary["pages"] as? UInt32 {
                    
                    // update targetPin with current request metadata for 'numOfPages'
                    targetPin.metaNumOfPages = numOfPages as NSNumber
                    self.getUpdatedPinByReference(targetPin) { (updatedPin, success, error) in
                        if (error != nil) { completionHandlerForSampleImages(false, error); return }
                        _ = updatedPin // refreshed pin currently not used <yet>
                    }
                    
                    DispatchQueue.main.async(execute: {
                        
                        for photoDictionary in photoResultArray {
                        
                            self.handlePhotoByFlickrUrl(photoDictionary["url_m"] as! String)
                            {
                                (imgDataOrigin, imgDataPreview, success, error) in
                                
                                if (error != nil) {
                                    
                                    completionHandlerForSampleImages(false, "Oops! Download could not be handled: \(String(describing: error!))")
                                    
                                } else {
                                
                                    if self.debugMode == true {
                                        print ("--- photo object successfully persisted ---")
                                        print ("    imageOrigin=\(imgDataOrigin!), imagePreview=\(imgDataPreview!)")
                                    }
                                }
                            }
                        }
                    })
                }
            }
        }
    }
}

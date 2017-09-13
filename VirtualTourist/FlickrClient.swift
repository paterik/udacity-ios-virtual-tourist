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
                        let maxPhotoIndex = photoResultArray.count
                        for (index, photoDictionary) in photoResultArray.enumerated() {
                        
                            // primary downloading process
                            self.handlePhotoByFlickrUrl(photoDictionary["url_m"] as! String, targetPin)
                            {
                                (imgDataOrigin, imgDataPreview, success, error) in
                                
                                if (error != nil) {
                                    
                                    completionHandlerForFetchFlickrImages(false, "Oops! Download could not be handled: \(error!)")
                                    
                                    return
                                    
                                } else {
                                    
                                    // notification push for single finished download step (used in locationMapView/photoAlbumView)
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name(rawValue: self.appDelegate.pinPhotoDownloadedNotification),
                                        object: nil,
                                        userInfo: [
                                            "completed": index == maxPhotoIndex - 1,
                                            "indexCurrent": index,
                                            "indexMax": maxPhotoIndex
                                        ]
                                    )
                                    
                                    if self.debugMode == true {
                                        // print ("--- photo object successfully persisted ---")
                                        print ("-> imageOrigin=\(imgDataOrigin!), imagePreview=\(imgDataPreview!), \(index + 1) of \(maxPhotoIndex) : \(self.appDelegate.pinPhotosCurrentlyDownloaded)")
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

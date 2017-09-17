//
//  FlickrClientExention.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 02.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import CoreStore
import Kingfisher

extension FlickrClient {
    
    func setPinNumberOfPagesByReference(
       _ pin: Pin,
       _ completionHandlerForUpdatedPin: @escaping (_ updatedPin: Pin?, _ success: Bool?, _ error: String?) -> Void) {
        
        let oldNumOfPages: UInt32 = pin.metaNumOfPages as! UInt32
        var newNumOfPages: UInt32 = 0
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Pin in
                
                guard let refPin = transaction.fetchOne(From<Pin>(), Where("metaHash", isEqualTo: pin.metaHash)) else {
                    completionHandlerForUpdatedPin(nil, false, "Oops! Pin reference lost in space ..."); return pin
                }
                
                refPin.metaNumOfPages = pin.metaNumOfPages; return refPin
            },
            
            success: { (transactionPin) in
                
                newNumOfPages = transactionPin.metaNumOfPages as! UInt32
                completionHandlerForUpdatedPin(CoreStore.fetchExisting(transactionPin)!, true, nil)
                
                if self.debugMode {
                    print ("\n-> pin object successfully updated ---")
                    print ("   metaNumOfPages(old)=\(oldNumOfPages)), metaNumOfPages(new)=\(newNumOfPages)\n")
                }
            },
            
            failure: { (error) in
                completionHandlerForUpdatedPin(nil, false, error.localizedDescription)
                if self.debugMode { print ("--- <failure> pin object processing/persistence failed: \(error) ---") }
                
                return
            }
        )
    }
    
    func getRandomPageFromPersistedPin(
       _ targetPin: Pin) -> UInt32 {
        
        if  let numOfPages = targetPin.metaNumOfPages {
            let maxNumOfPages = Int((Double(maxAllowedPages) / Double(appDelegate.pinMaxNumberOfPhotos)).rounded())
            
            var numPagesInt = numOfPages as! Int
                numPagesInt = (numPagesInt > maxNumOfPages) ? maxNumOfPages : numPagesInt
            
            return UInt32((arc4random_uniform(UInt32(numPagesInt)))) + 1
        }
        
        return 1
    }
    
    func getBoundingBoxAsString(
       _ pin: Pin) -> String {
        
        let btmLeftLon = max(pin.longitude - FlickrClientConstants.apiSearchBBoxParams._bbHalfWidth, FlickrClientConstants.apiSearchBBoxParams._lonMin)
        let btmLeftLat = max(pin.latitude - FlickrClientConstants.apiSearchBBoxParams._bbHalfHeight, FlickrClientConstants.apiSearchBBoxParams._latMin)
        let topRightLon = min(pin.longitude + FlickrClientConstants.apiSearchBBoxParams._bbHalfHeight, FlickrClientConstants.apiSearchBBoxParams._lonMax)
        let topRightLat = min(pin.latitude + FlickrClientConstants.apiSearchBBoxParams._bbHalfHeight, FlickrClientConstants.apiSearchBBoxParams._latMax)
        
        return NSString(format: "%f,%f,%f,%f", btmLeftLon, btmLeftLat, topRightLon, topRightLat) as String
    }
    
    /*
     *  This method seems to be the source of all headache I've had within the calculation of finale image processing -
     *  state. I'm still have this issue and try to calculate the finale image arrival to comply the cache cleanUp ..
     */
    func getDownloadedImageByFlickrUrl(
       _ imageUrl: String,
       _ imageExpectedCount: Int,
       _ imageLoopIndex: Int,
       _ completionHandlerForDowloadedImage: @escaping (_ rawImage: UIImage?, _ success: Bool?, _ error: String?) -> Void) {
        
        ImageDownloader.default.downloadTimeout = maxDownloadTimeout
        ImageDownloader.default.downloadImage(with: URL(string: imageUrl)!, options: [], progressBlock: nil)
        {
            (rawImage, error, url, data) in
            
            if (error != nil) {
                
                completionHandlerForDowloadedImage(nil, false, "\(String(describing: error!))")
                
                return
                
            } else {
                
                completionHandlerForDowloadedImage(rawImage, true, nil)
                
                // notification push for single finished download step (used in locationMapView/photoAlbumView)
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: self.appDelegate.pinPhotoDownloadedNotification),
                    object: nil, userInfo: ["indexCurrent": imageLoopIndex, "indexMax": imageExpectedCount]
                )
            }
        }
    }
    
    /*
     * This method will be called within the api result loop through all available image url's the corresponding 
     * request provide, start the download and handle the photo persistance ... This method is very restrictive!
     * We'll stop media-url handling on any problem occured during raw-/previewImage handling so as any http-call
     * thrown by our primary image downloader [getDownloadedImageByFlickrUrl(_)] ...
     */
    func handlePhotoByFlickrUrl (
       _ imageUrl: String,
       _ imageExpectedCount: Int,
       _ imageLoopIndex: Int,
       _ targetPin: Pin,
       _ completionHandlerForPhotoProcessor: @escaping (
            _ photo: Photo?,
            _ imgDataOrigin: Data?,
            _ imgDataPreview: Data?,
            _ success: Bool?,
            _ error: String?) -> Void) {
        
        // give handle to ImageDownloader processor ...
        self.getDownloadedImageByFlickrUrl(imageUrl, imageExpectedCount, imageLoopIndex) { (rawImage, success, error) in
            
            if (error != nil) {
                completionHandlerForPhotoProcessor(nil, nil, nil, false, error)
                if self.debugMode { print ("--- <failure> photo object download failed: \(String(describing: error?.description)) ---") }
                
                return
                
            } else {
                
                // now http/request error? okay start processing/preparing origin image
                guard let imageOrigin = UIImageJPEGRepresentation(rawImage!, 1) else {
                    completionHandlerForPhotoProcessor(nil, nil, nil, false, error); return
                }
                
                // now process/prepare thumbnail version of primary image (65% compression, 50% downscale)
                guard let imagePreview = UIImageJPEGRepresentation(
                    rawImage!.resized(withPercentage: self.photoPreviewDownscale)!, self.photoPreviewQuality) else {
                    completionHandlerForPhotoProcessor(nil, nil, nil, false, error); return
                }
                
                // and finally persist the media using our photo entity
                CoreStore.perform(
                    
                    asynchronous: { (transaction) -> Photo? in
                        
                        if let _pinRef = transaction.fetchOne(From<Pin>(), Where("metaHash", isEqualTo: targetPin.metaHash))
                        {
                            self.photo = transaction.create(Into<Photo>())
                            self.photo!.imageSourceURL = imageUrl
                            self.photo!.imageHash = imageUrl.md5()
                            self.photo!.imageRaw = imageOrigin
                            self.photo!.imagePreview = imagePreview
                            self.photo!.pin = _pinRef
                        
                            return self.photo!
                        }
                        
                        return nil
                        
                    },  success: { (transactionPhoto) in
                    
                        if transactionPhoto !== nil {
                            
                            // everything went fine! Go back to next image url provided by flickrApiGet looper :)
                            completionHandlerForPhotoProcessor(transactionPhoto, imageOrigin, imagePreview, true, nil)
                            
                        } else {
                        
                            completionHandlerForPhotoProcessor(nil, nil, nil, false, "Oops! Unable to persist location image!")
                            if self.debugMode { print ("--- <error> photo object processing/persistence not successfuly ---") }
                        }
                        
                    },  failure: { (error) in
                    
                        completionHandlerForPhotoProcessor(nil, nil, nil, false, "Oops! Failure during persisting location image: \(error)!")
                        if self.debugMode { print ("--- <failure> photo object processing/persistence failed: \(error) ---") }
                    }
                )
            }
        }
    }
    
    func getJSONFromStringArray(
       _ arrayData: [String : String]) -> String {
        
        var JSONString: String = "{}"
        
        do {
            
            let jsonData = try JSONSerialization.data(
                withJSONObject: arrayData,
                options: JSONSerialization.WritingOptions.prettyPrinted
            )
            
            if let _jsonString = String(data: jsonData, encoding: String.Encoding.utf8) { JSONString = _jsonString }
            
        } catch { if debugMode { print ("An error occured in FlickrClient::getJSONFromStringArray -> \(error)") } }
        
        return JSONString
    }
}

//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 02.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation

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
    
    //
    // MARK: Constants (API)
    //
    
    struct apiConfig {
        
        static let _url: String = "https://api.flickr.com/services/rest/"
        static let _pubKey: String = "945c147f91129f6f5a795b8a58f15852"
        static let _version: UInt8 = 1
        static let _format: String = "json"
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
    
    func getRandomPageFromPersistedPin(_ targetPin: Pin) -> UInt32 {
    
        if  let numOfPages = targetPin.metaNumOfPages {
            let maxNumOfPages = Int((Double(maxAllowedPages) / Double(maxPhotesEachPage)).rounded())
            
            var numPagesInt = numOfPages as! Int
                numPagesInt = (numPagesInt > maxNumOfPages) ? maxNumOfPages : numPagesInt
            
            return UInt32((arc4random_uniform(UInt32(numPagesInt))))
        }
        
        return 1
    }
    
    func getSampleImages (
       _ targetPin: Pin,
       _ completionHandlerForSampleImages: @escaping (_ success: Bool?, _ error: String?) -> Void) {
    
        let _requestParams = [
        
            apiBaseParams._format: apiConfig._format,
            apiBaseParams._page: "1",
            apiBaseParams._perPage: "16",
            apiBaseParams._noJSONCallback: "1",
            apiBaseParams._apiKey: apiConfig._pubKey,
            apiBaseParams._method: apiSearchParams.methodName,
            
            apiSearchParams.safeSearch: "1",
            apiSearchParams.accuracy: "1",
            apiSearchParams.contentType: "1",
            apiSearchParams.media: "photos",
            apiSearchParams.extras: "url_m",
            apiSearchParams.bbox: getBoundingBoxAsString(targetPin)
            
        ] as [String : AnyObject]
        
        client.get(apiConfig._url, headers: [:], parameters: _requestParams, bodyParameters: [:])
        {
            (data, error) in
            
            if (error != nil) {
                
                completionHandlerForSampleImages(false, "Oops! Your request could not be handled: \(String(describing: error!))")
                
            } else {
            
                // try to handle json result by binding specific keys (photos, photo and pages)
                if  let photoResultDictionary = data?.value(forKey: "photos") as? [String: AnyObject],
                    let photoResultArray = photoResultDictionary["photo"] as? [[String: AnyObject]],
                    let numOfPages = photoResultDictionary["pages"] as? UInt32 {
                    
                    DispatchQueue.main.async(execute: {
                        
                        targetPin.metaNumOfPages = NSNumber(value: numOfPages)
                        
                        for photoDictionary in photoResultArray {
                            
                            let photoURL = photoDictionary["url_m"] as! String
                            
                            print (photoURL)
                            print ("---")
                            // let photo = Photo(photoURL: photoURLString, pin: targetPin, context: self.sharedContext)
                        }
                    })
                    
                }
                
                completionHandlerForSampleImages(true, nil)
            }
        }
    }
}

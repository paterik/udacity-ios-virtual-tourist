//
//  FlickrClientConstants.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 12.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation

class FlickrClientConstants {

    //
    // MARK: Constants (Statics)
    //
    
    static let sharedInstance = FlickrClientConstants()
    
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
}

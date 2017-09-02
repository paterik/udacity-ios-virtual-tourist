//
//  FlickrClientExention.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 02.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation

extension FlickrClient {

    func getJSONFromStringArray(
       _ arrayData: [String : String]) -> String {
        
        var JSONString: String = "{}"
        
        do {
            
            let jsonData = try JSONSerialization.data(
                withJSONObject: arrayData,
                options: JSONSerialization.WritingOptions.prettyPrinted
            )
            
            if let _jsonString = String(data: jsonData, encoding: String.Encoding.utf8) { JSONString = _jsonString }
            
        } catch { if debugMode { print ("An Error occured in FlickrClient::getJSONFromStringArray -> \(error)") } }
        
        return JSONString
    }
    
    func getBoundingBoxAsString(_ pin: Pin) -> String {
        
        let btmLeftLon = max(pin.longitude - apiSearchBBoxParams._bbHalfWidth, apiSearchBBoxParams._lonMin)
        let btmLeftLat = max(pin.latitude - apiSearchBBoxParams._bbHalfHeight, apiSearchBBoxParams._latMin)
        let topRightLon = min(pin.longitude + apiSearchBBoxParams._bbHalfHeight, apiSearchBBoxParams._lonMax)
        let topRightLat = min(pin.latitude + apiSearchBBoxParams._bbHalfHeight, apiSearchBBoxParams._latMax)
        
        return NSString(format: "%f,%f,%f,%f", btmLeftLon, btmLeftLat, topRightLon, topRightLat) as String
    }
}

//
//  FlickrClientExention.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 02.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import CoreStore

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

    func getUpdatedPinByReference(
       _ pin: Pin,
       _ completionHandlerForUpdatedPin: @escaping (_ updatedPin: Pin?, _ success: Bool?, _ error: String?) -> Void) {
        
        let oldNumOfPages: UInt32 = pin.metaNumOfPages as! UInt32
        var newNumOfPages: UInt32 = 0
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Pin in
                
                guard let refPin = transaction.fetchOne(From<Pin>(), Where("metaHash", isEqualTo: pin.metaHash)) else {
                    completionHandlerForUpdatedPin(nil, false, "pin db reference not found!"); return pin
                }
                
                refPin.metaNumOfPages = pin.metaNumOfPages; return refPin
            },
            success: { (transactionPin) in
                
                newNumOfPages = transactionPin.metaNumOfPages as! UInt32
                completionHandlerForUpdatedPin(CoreStore.fetchExisting(transactionPin)!, true, nil)
                
                if self.debugMode == true {
                    print ("--- pin object successfully updated ---")
                    print ("    metaNumOfPages(old)=\(oldNumOfPages)), metaNumOfPages(new)=\(newNumOfPages)")
                }
            },
            failure: { (error) in
                completionHandlerForUpdatedPin(nil, false, error.localizedDescription)
            }
        )
    }
    
    func getRandomPageFromPersistedPin(
       _ targetPin: Pin) -> UInt32 {
        
        if  let numOfPages = targetPin.metaNumOfPages {
            let maxNumOfPages = Int((Double(maxAllowedPages) / Double(maxPhotesEachPage)).rounded())
            
            var numPagesInt = numOfPages as! Int
            numPagesInt = (numPagesInt > maxNumOfPages) ? maxNumOfPages : numPagesInt
            
            return UInt32((arc4random_uniform(UInt32(numPagesInt)))) + 1
        }
        
        return 1
    }
    
    func getBoundingBoxAsString(
       _ pin: Pin) -> String {
        
        let btmLeftLon = max(pin.longitude - apiSearchBBoxParams._bbHalfWidth, apiSearchBBoxParams._lonMin)
        let btmLeftLat = max(pin.latitude - apiSearchBBoxParams._bbHalfHeight, apiSearchBBoxParams._latMin)
        let topRightLon = min(pin.longitude + apiSearchBBoxParams._bbHalfHeight, apiSearchBBoxParams._lonMax)
        let topRightLat = min(pin.latitude + apiSearchBBoxParams._bbHalfHeight, apiSearchBBoxParams._latMax)
        
        return NSString(format: "%f,%f,%f,%f", btmLeftLon, btmLeftLat, topRightLon, topRightLat) as String
    }
}

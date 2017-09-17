//
//  StatisticViewControllerExtension.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 17.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import CoreStore

extension StatisticViewController {

    func setupUIDataPhotoAndStorageCount() {
        
        var sizeImageOriginKB: Double = 0.0
        var sizeImageSumKB: Double = 0.0
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [Photo]? in
                
                return transaction.fetchAll(From<Photo>())
            },
            
            success: { (transactionPhotos) in
                
                for _photo in transactionPhotos! {
                    
                    if  let _imageOrigin = _photo.imageRaw {
                        sizeImageOriginKB = Double(_imageOrigin.count) / 1024.0 / 1024.0
                        sizeImageSumKB += sizeImageOriginKB
                    }
                }
                
                if transactionPhotos?.isEmpty == false {
                    
                    self._statPhotoStorageInMb = sizeImageSumKB
                    self._statPhotosCount = transactionPhotos!.count
                    
                    self.lblPhotosCount.text = NSString(format: "%d", self._statPhotosCount) as String
                    self.lblPhotoStorageUsed.text = NSString(format: "%.02f MB", self._statPhotoStorageInMb) as String
                }
            },
            
            failure: { (error) in }
        )
    }
    
    func setupUIDataLocationCount() {
        
        btnResetLocations.isEnabled = false
        btnResetLocations.isHidden = true
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [Pin]? in
                
                return transaction.fetchAll(From<Pin>())
            },
            
            success: { (transactionPins) in
                
                if transactionPins?.isEmpty == false {
                    
                    self.btnResetLocations.isEnabled = true
                    self.btnResetLocations.isHidden = false
                    
                    self._statLocationsCount = transactionPins!.count
                    self.lblLocationCount.text = NSString(format: "%d", self._statLocationsCount) as String
                }
            },
            
            failure: { (error) in }
        )
    }
}

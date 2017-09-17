//
//  StatisticViewController.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 17.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import UIKit
import CoreStore

class StatisticViewController: BaseController {

    
    @IBOutlet weak var lblLocationCount: UILabel!
    @IBOutlet weak var lblPhotosCount: UILabel!
    @IBOutlet weak var lblPhotoStorageUsed: UILabel!
    @IBOutlet weak var btnResetLocations: UIButton!
    
    //
    // MARK: UIViewController Overrides
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIDataLocationCount()
        setupUIDataPhotoAndStorageCount()
    }
    
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
                    self.lblPhotosCount.text = NSString(format: "%d", transactionPhotos!.count) as String
                    self.lblPhotoStorageUsed.text = NSString(format: "%.02f MB", sizeImageSumKB) as String
                }
            },
            
            failure: { (error) in }
        )
    }
    
    func setupUIDataLocationCount() {
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [Pin]? in
                
                return transaction.fetchAll(From<Pin>())
            },
            
            success: { (transactionPins) in
                
                if transactionPins?.isEmpty == false {
                    self.lblLocationCount.text = NSString(format: "%d", transactionPins!.count) as String
                }
            },
            
            failure: { (error) in }
        )
    }
    
    @IBAction func btnResetLocationsAction(_ sender: Any) {
    
    }
    
    @IBAction func btnReturnToMapAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

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
    
    var _statLocationsCount: Int = 0
    var _statPhotosCount: Int = 0
    var _statPhotoStorageInMb: Double = 0.0
    
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
    
    @IBAction func btnResetLocationsAction(_ sender: Any) {
    
        let _message: String = "Do you realy want to reset all of your \(self._statLocationsCount) locations with \(self._statPhotosCount) photos?"
        
        let alert = UIAlertController(
            title: "Reset Locations",
            message: _message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "No, Cancel!", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes, Reset!", style: .default, handler: { (action: UIAlertAction) in
            
            CoreStore.perform(
                asynchronous: { (transaction) -> Void in
                    transaction.deleteAll(From<Pin>())
                },
                
                completion: { _ in
            
                    self.btnReturnToMapAction(self)
                }
            )
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnReturnToMapAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

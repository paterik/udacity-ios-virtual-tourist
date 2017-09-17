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
    
    //
    // MARK: IBAction Methods
    //
    
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

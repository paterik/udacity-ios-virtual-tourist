//
//  baseController.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 22.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import MapKit

class BaseController: UIViewController {
    
    //
    // MARK: Base Constants
    //
    
    let appDebugMode: Bool = true
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let mapEditModeInfoLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    let mapLoadingBar = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 5))
    
    //
    // MARK: Base Variables
    //
    
    func _handleErrorAsSimpleDialog(_ errorTitle: String, _ errorMessage: String) {
    
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}

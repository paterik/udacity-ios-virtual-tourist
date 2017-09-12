//
//  baseController.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 22.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import MapKit
import YNDropDownMenu

class BaseController: UIViewController {
    
    //
    // MARK: Base Constants
    //
    
    let appDebugMode: Bool = true
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let metaDateTimeFormat = "dd.MM.Y hh:mm"
    
    //
    // MARK: Base Variables
    //
    
    var appMenu: YNDropDownMenu?
    
    func _handleErrorAsSimpleDialog(_ errorTitle: String, _ errorMessage: String) {
    
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}

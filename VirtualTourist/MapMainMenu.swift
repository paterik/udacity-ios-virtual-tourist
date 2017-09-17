//
//  MapMainMenu.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 17.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import UIKit

class MapMainMenu: UIView {

    //
    // MARK: IBOutlet Variables
    //
    
    @IBOutlet weak var btnShowSettings: UIButton!
    @IBOutlet weak var btnShowStatistics: UIButton!
    
    //
    // MARK: Variables
    //
    
    var delegate: ControllerCommandProtocol?
    
    //
    // MARK: IBOutlet Methods
    //
    
    @IBAction func btnShowSettingsAction(_ sender: Any) {
        
        if let del = delegate { del.handleDelegateCommand("showSettingsForApp") }
        
    }

    @IBAction func btnShowStatisticsAction(_ sender: Any) {
    
        if let del = delegate { del.handleDelegateCommand("showStatisticsForApp") }
    }
}

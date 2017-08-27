//
//  Pin.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 24.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CryptoSwift

class Pin: NSManagedObject, MKAnnotation {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var numPages: NSNumber?
    @NSManaged var photos: [Photo]
    @NSManaged var metaHash: String
    
    var coordinate: CLLocationCoordinate2D {
        
        get { return CLLocationCoordinate2DMake(latitude, longitude) }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
            self.metaHash = "\(self.latitude)-\(self.longitude)".md5()
        }
    }
}

//
//  Photo.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 24.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import CoreData
import CoreStore
import MapKit

class Photo: NSManagedObject {
    
    @NSManaged var imageSourceURL: String
    @NSManaged var imageRaw: Data?
    @NSManaged var imagePreview: Data?
    @NSManaged var imageHash: String
    @NSManaged var pin: Pin?
}

struct PhotoCellObject {
    
    var imageHash: String?
    var imageSourceURL: String?
    var imageOrigin: UIImage?
    var imagePreview: UIImage?
    var isPlaceHolder: Bool = false
}

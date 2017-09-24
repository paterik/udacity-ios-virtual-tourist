//
//  Photo.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 24.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import CoreStore

class Photo: NSManagedObject {
    
    @NSManaged var imageSourceURL: String
    @NSManaged var imageRaw: Data?
    @NSManaged var imagePreview: Data?
    @NSManaged var imageHash: String
    @NSManaged var pin: Pin?
}


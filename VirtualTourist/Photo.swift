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

struct PhotoQueueObject {
    
    var _metaHash: String?
    var _metaQueueIndex: Int?
    var _metaQueueCreatedAt: Date?
    var _metaQueueUpdatedAt: Date?
    var _metaLocationHash: String?
    var _metaDownloadCompleted: Bool?
    var _metaDownloadMsg: String?
    var _metaDataSizeRaw: Double?
    var _metaDataSizeConverted: Double?
    
    init(metaHash: String?,
         metaQueueIndex: Int?,
         metaQueueCreatedAt: Date?,
         metaQueueUpdatedAt: Date?,
         metaLocationHash: String?,
         metaDownloadCompleted: Bool?,
         metaDownloadMsg: String?,
         metaDataSizeRaw: Double?,
         metaDataSizeConverted: Double?) {
        
        self._metaHash = metaHash
        self._metaQueueIndex = metaQueueIndex
        self._metaQueueCreatedAt = metaQueueCreatedAt
        self._metaQueueUpdatedAt = metaQueueUpdatedAt
        self._metaLocationHash = metaLocationHash
        self._metaDownloadCompleted = metaDownloadCompleted
        self._metaDownloadMsg = metaDownloadMsg
        self._metaDataSizeRaw = metaDataSizeRaw
        self._metaDataSizeConverted = metaDataSizeConverted
        
    }
}

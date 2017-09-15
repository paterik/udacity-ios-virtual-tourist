//
//  PhotoQueueItem.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 15.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import UIKit

struct PhotoQueueItem {
    
    var _metaHash: String?
    var _metaQueueIndex: Int?
    var _metaQueueCreatedAt: Date?
    var _metaQueueUpdatedAt: Date?
    var _metaLocationHash: String?
    var _metaDownloadAsCellProcessed: Bool?
    var _metaDownloadCompleted: Bool?
    var _metaDownloadMsg: String?
    var _metaDataSizeRaw: Double?
    var _metaDataSizeConverted: Double?
    var _imageSourceURL: String?
    var _imageJPEGRaw: UIImage?
    var _imageJPEGConverted: UIImage?
    var _photo: Photo?
    
    init(metaHash: String?,
         metaQueueIndex: Int?,
         metaQueueCreatedAt: Date?,
         metaQueueUpdatedAt: Date?,
         metaLocationHash: String?,
         metaDownloadAsCellProcessed: Bool?,
         metaDownloadCompleted: Bool?,
         metaDownloadMsg: String?,
         metaDataSizeRaw: Double?,
         metaDataSizeConverted: Double?,
         imageSourceURL: String?,
         imageJPEGRaw: UIImage?,
         imageJPEGConverted: UIImage?,
         photo: Photo?) {
        
        self._metaHash = metaHash
        self._metaQueueIndex = metaQueueIndex
        self._metaQueueCreatedAt = metaQueueCreatedAt
        self._metaQueueUpdatedAt = metaQueueUpdatedAt
        self._metaLocationHash = metaLocationHash
        self._metaDownloadAsCellProcessed = metaDownloadAsCellProcessed
        self._metaDownloadCompleted = metaDownloadCompleted
        self._metaDownloadMsg = metaDownloadMsg
        self._metaDataSizeRaw = metaDataSizeRaw
        self._metaDataSizeConverted = metaDataSizeConverted
        self._imageSourceURL = imageSourceURL
        self._imageJPEGRaw = imageJPEGRaw
        self._imageJPEGConverted = imageJPEGConverted
        self._photo = photo
        
    }
}

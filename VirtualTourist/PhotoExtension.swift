//
//  PhotoExtension.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 15.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import UIKit

extension Photo {
    
    public func convertToPhotoQueueObject(_ queueIndex: Int) -> PhotoQueueItem {
        
        var UIImageOrigin: UIImage?
        var UIImagePreview: UIImage?
        var sizeImageOrigin: Double = 0.0
        var sizeImagePreview: Double = 0.0
        
        if let _imageOrigin = self.imageRaw {
            UIImageOrigin = UIImage(data: _imageOrigin, scale: 1.0)
            sizeImageOrigin = Double(_imageOrigin.count) / 1024.0
        }
        
        if let _imagePreview = self.imagePreview {
            UIImagePreview = UIImage(data: _imagePreview, scale: 1.0)
            sizeImagePreview = Double(_imagePreview.count) / 1024.0
        }
        
        return PhotoQueueItem(
            metaHash: self.imageSourceURL.md5(),
            metaQueueIndex: queueIndex,
            metaQueueCreatedAt: Date(),
            metaQueueUpdatedAt: Date(),
            metaLocationHash: self.pin!.metaHash,
            metaDownloadAsCellProcessed: true,
            metaDownloadCompleted: true,
            metaDownloadMsg: "persisted photo #\(queueIndex) from \(self.imageSourceURL)",
            metaDataSizeRaw: sizeImageOrigin,
            metaDataSizeConverted: sizeImagePreview,
            imageSourceURL: self.imageSourceURL,
            imageJPEGRaw: UIImageOrigin,
            imageJPEGConverted: UIImagePreview,
            photo: self
        )
    }
}

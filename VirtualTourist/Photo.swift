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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    public static func create(
        imageSourceUrl: String,
        imageOrigin: Data,
        imagePreview: Data,
        targetPin: Pin) -> Photo? {
        
        var photo: Photo!
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Photo? in
                
                let _pin = transaction.fetchOne(
                    From<Pin>(),
                    Where("metaHash", isEqualTo: targetPin.metaHash)
                )
                
                photo = transaction.create(Into<Photo>())
                photo.imageSourceURL = imageSourceUrl
                photo.imageHash = imageSourceUrl.md5()
                photo.imageRaw = imageOrigin
                photo.imagePreview = imagePreview
                photo.pin = _pin!
                
                return photo
                
            },  success: { (transactionPhoto) in
            
                photo = CoreStore.fetchExisting(transactionPhoto!)
            
            },  failure: { (error) in
            
                print ("--- photo object processing/persistence failed ---")
            
                return
            }
        )
        
        return photo
    }
}

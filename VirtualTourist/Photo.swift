//
//  Photo.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 24.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {
    
    @NSManaged var photoURL: String
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
    
    init(photoURL: String, pin: Pin, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context)!
        super.init(entity: entity, insertInto: context)
        
        self.photoURL = photoURL
        self.pin = pin
    }
    
    var image: UIImage? {
        
        if imagePath != nil {
            let fileURL = getFileURL()
            return UIImage(contentsOfFile: fileURL.path)
        }
        
        return nil
    }
    
    func getFileURL() -> URL {
        
        let fileName = (imagePath! as NSString).lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let pathArray:[String] = [dirPath, fileName]
        let fileURL = NSURL.fileURL(withPathComponents: pathArray)
        
        return fileURL!
    }
    
    override func prepareForDeletion() {
        
        if (imagePath == nil) { return }
        
        let fileURL = getFileURL()
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            
            do {
                
                try FileManager.default.removeItem(atPath: fileURL.path)
                
            } catch let error as NSError {
                
                print(error.userInfo)
                
            }
        }
    }
}

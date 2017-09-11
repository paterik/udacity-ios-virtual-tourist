//
//  MapDetailViewControllerExtension.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 10.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import CoreStore

extension MapDetailViewController {

    func cleanUpCollectionCache() {
    
        self.photoObjects.removeAll()
        self.photoDataObjects.removeAll()
    }
    
    func deletePhotosOfCollectionByPin (
       _ pin: Pin,
       _ completionHandlerForDeletePhotos: @escaping (_ success: Bool?, _ error: String?) -> Void) {
    
        cleanUpCollectionCache()
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                transaction.deleteAll(From<Photo>(), Where("pin", isEqualTo: pin))
            },
            
            success: { _ in
        
                completionHandlerForDeletePhotos(true, nil)
            },
            
            failure: { (error) in
                
                completionHandlerForDeletePhotos(false, error.localizedDescription)
                
                return
            }
        )
    }
    
    func getPhotosForCollectionByPin (
       _ pin: Pin,
       _ completionHandlerForFetchPhotos: @escaping (_ photos: [Photo]?, _ success: Bool?, _ error: String?) -> Void) {
        
        cleanUpCollectionCache()
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [Photo]? in
                
                return transaction.fetchAll(From<Photo>(), Where("pin", isEqualTo: pin))
            },
            
            success: { (transactionPhotos) in
                
                if transactionPhotos?.isEmpty == true {
                    completionHandlerForFetchPhotos(nil, false, "Oops! No photos found for this location ...")
                }   else {
                    completionHandlerForFetchPhotos(transactionPhotos!, true, nil)
                }
            },
            
            failure: { (error) in
                
                completionHandlerForFetchPhotos(nil, false, error.localizedDescription)
                return
            }
        )
    }
    
    func refreshCollectionView() {
        
        if isDataAvailable() {
            photoCollectionView?.reloadData()
            print ("-> reload image data")
        }
    }
    
    func isDataAvailable() -> Bool {
        
        return photoObjects.count > 0
    }
}

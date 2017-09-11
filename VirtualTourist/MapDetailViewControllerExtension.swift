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

    func loadViewAdditions() {
        
        mapNoPhotosInfoLabel.backgroundColor = UIColor(netHex: 0xEC2C61)
        mapNoPhotosInfoLabel.textColor = UIColor(netHex: 0xFFFFFF)
        mapNoPhotosInfoLabel.textAlignment = .center
        mapNoPhotosInfoLabel.text = "There are no photoa available for this location"
        mapNoPhotosInfoLabel.isEnabled = false
        mapNoPhotosInfoLabel.isHidden = true
        
        view.addSubview(mapNoPhotosInfoLabel)
        
        mapNoPhotosInfoLabel.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.width.equalTo(self.view)
            make.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-44)
        }
    }
    
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
                    completionHandlerForFetchPhotos(nil, true, "Warning! No images found for this location ...")
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
            
            if appDebugMode { print ("-> reload image data") }
            photoCollectionView?.reloadData()
            
        } else {
        
            if appDebugMode { print ("-> no image data available") }
            mapNoPhotosInfoLabel.isEnabled = true
            mapNoPhotosInfoLabel.isHidden = false
        }
    }
    
    func isDataAvailable() -> Bool {
        
        return photoObjects.count > 0
    }
}

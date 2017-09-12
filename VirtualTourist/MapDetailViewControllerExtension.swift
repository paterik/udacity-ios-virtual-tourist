//
//  MapDetailViewControllerExtension.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 10.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import CoreStore
import UIKit
import MapKit

extension MapDetailViewController {

    func loadViewAdditions() {
        
        btnRefreshPhotosForThisLocation.isEnabled = true
        
        mapNoPhotosInfoLabel.text = "There are no photoa available for this location"
        mapNoPhotosInfoLabel.backgroundColor = UIColor(netHex: 0xEC2C61)
        mapNoPhotosInfoLabel.textColor = UIColor(netHex: 0xFFFFFF)
        mapNoPhotosInfoLabel.textAlignment = .center
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
    
        photoObjects.removeAll()
        photoDataObjects.removeAll()
        photoCollectionView?.reloadData()
    }
    
    func deletePhotosOfCollectionByPin (
       _ pin: Pin,
       _ completionHandlerForDeletePhotos: @escaping (_ success: Bool?, _ error: String?) -> Void) {
    
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                transaction.deleteAll(From<Photo>(), Where("pin", isEqualTo: pin))
            },
            
            success: { _ in
                
                self.cleanUpCollectionCache()
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
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [Photo]? in
                
                return transaction.fetchAll(From<Photo>(), Where("pin", isEqualTo: pin))
            },
            
            success: { (transactionPhotos) in
                
                self.cleanUpCollectionCache()
                
                if transactionPhotos?.isEmpty == true {
                    
                    completionHandlerForFetchPhotos(nil, true, "Warning! No images found for this location ...")
                    
                }  else {
                    
                    completionHandlerForFetchPhotos(transactionPhotos!, true, nil)
                    
                }
            },
            
            failure: { (error) in
                
                completionHandlerForFetchPhotos(nil, false, error.localizedDescription)
            }
        )
    }
    
    func convertPhotoToPhotoCellObject(_ photo: Photo) -> PhotoCellObject {
        
        var UIImageOrigin: UIImage?
        var UIImagePreview: UIImage?
        
        if let _imageOrigin = photo.imageRaw {
            UIImageOrigin = UIImage(data: _imageOrigin, scale: 1.0)
        }
        
        if let _imagePreview = photo.imagePreview {
            UIImagePreview = UIImage(data: _imagePreview, scale: 1.0)
        }
        
        return PhotoCellObject(
            imageHash: photo.imageHash,
            imageSourceURL: photo.imageSourceURL,
            imageOrigin: UIImageOrigin,
            imagePreview: UIImagePreview
        )
    }
    
    func setupUICollectionView() {
        
        photoCollectionView.isHidden = false
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
    }
    
    func setupUIMap() {
        
        // @todo (v1.0.n): move this as property pack deep inside the corresponding PIN entity
        let pinCenter = CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        let pinRegion = MKCoordinateRegion(center: pinCenter, span: MKCoordinateSpan(latitudeDelta: 0.375, longitudeDelta: 0.375))
        
        miniMapView.delegate = self
        miniMapView.setRegion(pinRegion, animated: true)
        miniMapView.setCenter(pin.coordinate, animated: true)
        miniMapView.addAnnotation(pin)
    }
    
    func validateLastPhotoTransfered(_ notification: NSNotification?) -> Bool {
    
        if notification == nil { return false }
        
        if let userInfo = notification!.userInfo as? [String: Bool]
        {
            pin.isDownloading = true
            
            if let completed = userInfo["completed"] {
                if completed == true {
                    pin.isDownloading = false
                    toggleRefreshCollectionButton(true)
                    
                    return true
                }
            }
        }
        
        return false
    }
    
    func loadPhotosForCollectionView(_ notification: NSNotification?) {
        
        // handle normal photo collectionView for persisted locations
        if pin.photos.count > 0 {
            
            getPhotosForCollectionByPin(pin) {
                
                (photos, success, error) in
                
                if success == true {
                    
                    if photos != nil {
                        
                        self.photoDataObjects = photos!
                        for photo in self.photoDataObjects {
                            self.photoObjects.append(self.convertPhotoToPhotoCellObject(photo))
                        }
                    }
                    
                    let _ = self.validateLastPhotoTransfered(notification)
                    self.refreshCollectionView()
                    
                } else {
                    
                    if self.appDebugMode { print (error ?? "unknown image handler problem") }
                }
            }
            
        // handle empy locations, set placeholders
            
        } else {
            
        }
    }
    
    func toggleRefreshCollectionButton(_ enabled: Bool) {
        
        btnRefreshPhotosForThisLocation.isEnabled = enabled
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

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
    
    func cleanUpCollectionCache() {
    
        photoObjects.removeAll()
        photoDataObjects.removeAll()
        photoCellIndexRefreshed = 0
        
        // prepare image cache for the number of photos previously persisted for this pin
        addCollectionPlaceHolderPhotos(photoCellIndexOldTreshold)
        
        // reload collectionView to show/refresh items
        photoCollectionView?.reloadData()
    }
    
    func addCollectionPlaceHolderPhotos(_ number: Int) {

        // reset async photo download/processing counter
        appDelegate.pinPhotosCurrentlyDownloaded = 0
        
        // build placeholder imageStack after cleanUp old (real) image collection(s)
        for index in 0 ... number - 1  {
            self.photoObjects.append(PhotoCellObject(
                imageHash: "\(index)".md5(),
                imageSourceURL: "\(index)",
                imageOrigin: UIImage(named: "imgPhotoPlaceholder_v1"),
                imagePreview: nil,
                isPlaceHolder: true
            ))
        }
    }
    
    func deletePhotosOfCollectionByPin (
       _ pin: Pin,
       _ completionHandlerForDeletePhotos: @escaping (_ success: Bool?, _ error: String?) -> Void) {
    
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
       _ completionHandlerForFetchPhotos: @escaping (_ photos: [Photo]?, _ success: Bool?, _ error: String?) -> Void) {
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [Photo]? in
                
                return transaction.fetchAll(From<Photo>(), Where("pin", isEqualTo: self.pin))
            },
            
            success: { (transactionPhotos) in
                
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
            imagePreview: UIImagePreview,
            isPlaceHolder: false
        )
    }
    
    func setupUICollectionView() {
        
        photoCollectionView.isHidden = false
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
    }
    
    func setupUIMap() {
        
        let pinCenter = CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        let pinRegion = MKCoordinateRegion(center: pinCenter, span: MKCoordinateSpan(latitudeDelta: 0.375, longitudeDelta: 0.375))
        
        miniMapView.delegate = self
        miniMapView.setRegion(pinRegion, animated: true)
        miniMapView.setCenter(pin.coordinate, animated: true)
        miniMapView.addAnnotation(pin)
    }
    
    func getIndexOfDownloadedPhoto(_ notification: NSNotification?) -> Int {
    
        if notification == nil { return -1 }
        
        if let userInfo = notification!.userInfo as? [String: Any]
        {
            if let refreshedIndex = userInfo["indexCurrent"] {
                
                return refreshedIndex as! Int
            }
        }
        
        return 0
    }
    
    func getMaxIndexOfCurrentDownloadSession(_ notification: NSNotification?) -> Int {
        
        if notification == nil { return -1 }
        
        if let userInfo = notification!.userInfo as? [String: Any]
        {
            if let refreshedIndex = userInfo["indexMax"] {
                
                return refreshedIndex as! Int
            }
        }
        
        return 0
    }

    
    func loadPhotosForCollectionView(_ notification: NSNotification?) {
        
        getPhotosForCollectionByPin() {
                
            (photos, success, error) in
                
            if success == true {
                    
                if photos != nil {
                        
                    self.photoDataObjects = photos!
                    
                    if notification == nil {
                        
                        // remove complete placeholder imageStack
                        self.photoObjects.removeAll()
                        for photo in self.photoDataObjects {
                            self.photoObjects.append(self.convertPhotoToPhotoCellObject(photo))
                        }
                    
                    } else {
                        
                        // check old photo number threshold and extend placeholder stack if necessary
                        self.mapNoPhotosInfoLabel.text = self.mapMsgPhotosInDownload
                        self.mapNoPhotosInfoLabel.backgroundColor = UIColor(netHex: 0x23A7CE)
                        
                        self.photoCellIndexNewTreshold = self.getMaxIndexOfCurrentDownloadSession(notification)
                        if (self.photoCellIndexOldTreshold != self.photoCellIndexNewTreshold) && self.photoCellIndexFixed == false {
                            
                            if self.appDebugMode {
                                print ("--> detected treshold missmatch (\(self.photoCellIndexNewTreshold) vs \(self.photoCellIndexOldTreshold) photos)")
                            }
                            
                            self.addCollectionPlaceHolderPhotos(self.photoCellIndexNewTreshold - self.photoCellIndexOldTreshold)
                            self.photoCellIndexFixed = true
                        }
                        
                        // replace placeholder imageStack (step wise)
                        let  photoCellObject: PhotoCellObject = self.convertPhotoToPhotoCellObject(self.photoDataObjects[self.photoCellIndexRefreshed])
                        self.photoObjects[self.photoCellIndexRefreshed] = photoCellObject
                        self.photoCellIndexRefreshed += 1
                        
                        // ahhhhhhhhhhhhh still won't working :( !!!!!
                        if self.appDelegate.pinPhotosCurrentlyDownloaded == self.photoCellIndexNewTreshold {
                            
                            /*print ("")
                            print ("!!!!!!!!!!!!!!!!!")
                            print ("!!! COMPLETED !!!")
                            print ("!!!!!!!!!!!!!!!!!")
                            print ("")*/
                            
                            self.pin.isDownloading = false
                            self.toggleRefreshCollectionButton(true)
                            self.toggleNoPhotosFoundInfoBox(false)
                            
                            // self.cleanUpCollectionViewCache()
                            // self.refreshCollectionView()
                        }
                    }
                }
                
                self.refreshCollectionView()
                    
            } else {
                    
                if self.appDebugMode { print (error ?? "unknown image handler problem") }
            }
        }
    }
    
    func cleanUpCollectionViewCache() {
    
        print ("===> cleanUp collectionView ...")
        for (index, photo) in photoObjects.enumerated() {
            if photo.isPlaceHolder {
                print ("===> photo #\(index) of db_max:\(photoDataObjects.count) and preview_max:\(photoObjects.count) is bad <===")
                if index <= self.photoObjects.count {
                    photoObjects.remove(at: index)
                }
            }
        }
    }
    
    func loadViewAdditions() {
        
        btnRefreshPhotosForThisLocation.isEnabled = true
        
        mapNoPhotosInfoLabel.text = mapMsgNoPhotosAvailable
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
    
    func toggleNoPhotosFoundInfoBox(_ enabled: Bool) {
        
        mapNoPhotosInfoLabel.isEnabled = enabled
        mapNoPhotosInfoLabel.isHidden = !enabled
    }
    
    func toggleRefreshCollectionButton(_ enabled: Bool) {
        
        btnRefreshPhotosForThisLocation.isEnabled = enabled
    }
    
    func refreshCollectionView() {
        
        if isDataAvailable() {
            
            // if appDebugMode { print ("\n--> reload image data\n") }
            photoCollectionView?.reloadData()
            
        } else {
        
            // if appDebugMode { print ("--> no image data available") }
            toggleNoPhotosFoundInfoBox(true)
        }
    }
    
    func isDataAvailable() -> Bool {
        
        return photoObjects.count > 0
    }
}

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
    
    func deletePhotosOfCollectionByMetaHash(
       _ photoMetaHash: String,
       _ completionHandlerForDeletePhotos: @escaping (_ success: Bool?, _ error: String?) -> Void) {
    
         CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                transaction.deleteAll(From<Photo>(), Where("imageHash", isEqualTo: photoMetaHash))
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
    
    func getMaxIndexOfCurrentDownloadSession(
       _ notification: NSNotification?) -> Int {
        
        if notification == nil { return 0 }
        
        if let userInfo = notification!.userInfo as? [String: Any]
        {
            if let refreshedIndex = userInfo["indexMax"] {
                return refreshedIndex as! Int
            }
        }
        
        return 0
    }
    
    func getCellImageForPhoto(
       _ photoQueueItem: PhotoQueueItem) -> UIImage {
        
        var cellPhotoImage: UIImage = UIImage(named: "imgPhotoPlaceholder_v1")!
        
        if  photoQueueItem._metaDownloadCompleted! &&
            photoQueueItem._imageJPEGConverted != nil {
            
            cellPhotoImage = photoQueueItem._imageJPEGConverted!
            
        } else if photoQueueItem._metaDownloadCompleted! &&
                  photoQueueItem._imageJPEGRaw != nil {
            
            cellPhotoImage = photoQueueItem._imageJPEGRaw!
        }
        
        cellPhotoImage = cellPhotoImage.alpha(1)
        if  photoQueueItem._imageCellSelected! {
            cellPhotoImage = cellPhotoImage.alpha(cellPhotoImageAlphaForSelected)
        }
        
        return cellPhotoImage
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
    
    func setupUIReloadButton() {
        
        btnRefreshPhotosForThisLocation.image = UIImage(named: "icnRefresh_v2")
        let numberOfSelections: Int = selectedIndexes.count
        if  numberOfSelections > 0 && numberOfSelections <= appDelegate.pinMaxNumberOfPhotos {
            
            btnRefreshPhotosForThisLocation.image = UIImage(named: "icnRefresh_v2_n\(numberOfSelections)")
        }
    }
    
    func getSecondsBetweenTwoDates(
       _ startDate: Date,
       _ endDate: Date) -> Int {
        
        let calendar = Calendar.current
        let unitFlags = Set<Calendar.Component>([ .second])
        let datecomponenets = calendar.dateComponents(unitFlags, from: startDate, to: endDate)
        
        return datecomponenets.second!
    }
    
    // obsolete, will be removed in future version (#R.1001)
    func cleanUpCollectionViewCache() {
        for (index, photo) in appDelegate.photoQueue.enumerated() {
            if photo._metaDownloadCompleted == false {
                if index <= appDelegate.photoQueue.count {
                    appDelegate.photoQueue.remove(at: index)
                }
            }
        }
    }
    
    func cleanUpCollectionCache() {
        
        // reset async photo data/download/processing queue
        appDelegate.photoDataObjects.removeAll()
        appDelegate.photoQueue.removeAll()
        appDelegate.photoQueueImagesDownloaded = 0
        photoCollectionView?.reloadData()
    }
    
    func loadPhotosForCollectionView(
       _ notification: NSNotification?) {
        
         getPhotosForCollectionByPin() {
            
            (photos, success, error) in
            
            if success == true {
                
                if photos != nil {
                    
                    self.appDelegate.photoDataObjects = photos!
                    
                    //
                    // mode 1: normal loading of persisted photo stack
                    //
                    
                    if notification == nil {
                        
                        // remove complete placeholder imageStack
                        self.appDelegate.photoQueue.removeAll()
                        for (index, photo) in self.appDelegate.photoDataObjects.enumerated() {
                            self.appDelegate.photoQueue.append(photo.convertToPhotoQueueObject(index))
                        }
                        
                        //
                        // mode 2: event based refresh loading of new persisted photo sack
                        //
                        
                    } else {
                        
                        // determine the maximal photo stack count available from last api request
                        self.appDelegate.photoQueueImagesAvailable = self.getMaxIndexOfCurrentDownloadSession(notification)
                        self.appDelegate.photoQueueImagesDownloaded = 0 // ... and cleanUp download counter
                        
                        // iterate through complete image stack to fetch the latest downloaded image
                        for (queueIndex, queueItem) in self.appDelegate.photoQueue.enumerated() {
                            
                            // count current download stack position to predict download finish line
                            if queueItem._metaDownloadCompleted! == true { self.appDelegate.photoQueueImagesDownloaded += 1 }
                            // try to fetch a photo which was downloaded but currently not presented as cell
                            if  queueItem._metaDownloadCompleted! == true &&
                                queueItem._metaDownloadAsCellProcessed == false {
                                
                                var queueObjectToUpdate = self.appDelegate.photoQueue[queueIndex]
                                    queueObjectToUpdate._metaDownloadAsCellProcessed = true
                                    queueObjectToUpdate._metaQueueUpdatedAt = Date()
                                
                                self.appDelegate.photoQueue[queueIndex] = queueObjectToUpdate
                            }
                        }
                        
                        // check queue final state and cleanUp cache/placeholder fragments
                        if self.appDelegate.photoQueueImagesDownloaded == self.appDelegate.photoQueueImagesAvailable - 1 {
                            
                            self.pin.isDownloading = false
                            self.toggleRefreshCollectionButton(true)
                            self.toggleCollectionViewInfoLabel(false)                        }
                    }
                }
                
                self.refreshCollectionView()
                
            } else {
                
                if self.appDebugMode { print (error ?? "unknown image handler problem") }
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
            make.height.equalTo( 50 )
            make.width.equalTo(self.view)
            make.bottom.equalTo(bottomLayoutGuide.snp.top).offset( -44 )
        }
    }
    
    func toggleCollectionViewInfoLabel(_ enabled: Bool) {
        
        mapNoPhotosInfoLabel.isEnabled = enabled
        mapNoPhotosInfoLabel.isHidden = !enabled
    }
    
    func toggleRefreshCollectionButton(_ enabled: Bool) {
        
        btnRefreshPhotosForThisLocation.isEnabled = enabled
        setupUIReloadButton()
    }
    
    func addCellIndexToSelection (
       _ indexPath: IndexPath) {
        
        selectedIndexes.append(indexPath)
    }
    
    func removeCellIndexFromSelection (
       _ indexPath: IndexPath) {
        
        for (index, indexPathValue) in selectedIndexes.enumerated() {
            if indexPathValue == indexPath {
                selectedIndexes.remove(at: index); return
            }
        }
    }
    
    func replacePhotosOfCollectionFromSelection() {
        
        for (_, indexPath) in selectedIndexes.enumerated() {
            
            if appDebugMode == true { print ("=> replace index \(indexPath.row) from stack") }
            
            let updatedCell = photoCollectionView.cellForItem(at: indexPath) as! FlickrCell
            var cellObjectToUpdate = self.appDelegate.photoQueue[indexPath.row]
                cellObjectToUpdate._metaDownloadCompleted = false
                self.appDelegate.photoQueue[indexPath.row] = cellObjectToUpdate
            
            updatedCell.imageView.image = getCellImageForPhoto(cellObjectToUpdate)
            updatedCell.activityIndicator.startAnimating()
            updatedCell.activityIndicator.isHidden = false
        }
        
        toggleRefreshCollectionButton(true)
        refreshCollectionView()
    }
    
    func deletePhotosOfCollectionBySelection() {
        
        for (_, indexPath) in selectedIndexes.enumerated() {
            
            let updatedCell = photoCollectionView.cellForItem(at: indexPath) as! FlickrCell
            var cellObjectToUpdate = self.appDelegate.photoQueue[indexPath.row]
                cellObjectToUpdate._metaDownloadCompleted = false
                appDelegate.photoQueue[indexPath.row] = cellObjectToUpdate
            
            updatedCell.imageView.image = getCellImageForPhoto(cellObjectToUpdate)
            updatedCell.activityIndicator.startAnimating()
            updatedCell.activityIndicator.isHidden = false
            
            if appDebugMode == true {
                print ("=> delete index \(indexPath.row) from stack using metaHash \(cellObjectToUpdate._metaHash!)")
            }
            
            self.deletePhotosOfCollectionByMetaHash(cellObjectToUpdate._metaHash!) {
                
                (success, error) in
                
                // delete successfully done?
                if error == nil {
                    
                    self.appDelegate.photoQueue.remove(at: indexPath.row)
                    self.removeCellIndexFromSelection(indexPath)
                    self.loadPhotosForCollectionView(nil)
                    self.refreshCollectionView()
                    self.toggleRefreshCollectionButton(true)
                }
            }
        }
    }
    
    func resetSelectionForCollectionView() {
        
        for (_, indexPath) in selectedIndexes.enumerated() {
            
            if appDebugMode == true { print ("=> reset index \(indexPath.row) from stack") }
            
            removeCellIndexFromSelection(indexPath)
            
            let updatedCell = photoCollectionView.cellForItem(at: indexPath) as! FlickrCell
            var cellObjectToUpdate = self.appDelegate.photoQueue[indexPath.row]
            cellObjectToUpdate._metaDownloadCompleted = true
            cellObjectToUpdate._imageCellSelected = false
            
            updatedCell.imageView.image = getCellImageForPhoto(cellObjectToUpdate)
            updatedCell.activityIndicator.stopAnimating()
            updatedCell.activityIndicator.isHidden = true
            
            appDelegate.photoQueue[indexPath.row] = cellObjectToUpdate
        }
        
        toggleRefreshCollectionButton(true)
    }
    
    func callPhotoManagementByPin() {
        
        toggleRefreshCollectionButton(false)
        
        let alert = UIAlertController(
            title: "Delete Collection",
            message: "Do you really want to refresh this collection by loading new images?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "No, Cancel!", style: .default, handler: { (action: UIAlertAction) in
            self.toggleRefreshCollectionButton(true)
        }))
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
            
            self.deletePhotosOfCollectionByPin(self.pin) {
                
                (success, error) in
                
                // delete successfully done?
                if error == nil {
                    
                    // clean collection view cache and load preset images
                    self.cleanUpCollectionCache()
                    
                    // load new imageSet using flickr api call
                    self.flickrClient.getImagesByMapPin (self.pin!, nil) {
                        
                        (success, error) in
                        
                        if success == false || error != nil {
                            
                            self._handleErrorAsSimpleDialog("Error", error?.description ?? "unkown error occurred")
                        }
                    }
                }
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func callPhotoManagementBySelection() {
        
        toggleRefreshCollectionButton(false)
        
        var _title: String   = "Replace \(selectedIndexes.count) Photos"
        var _message: String = "Do you want to replace the \(selectedIndexes.count) photos by new ones or just delete them?"
        var _btnTitleDelete: String = "DELETE \(selectedIndexes.count) photos"
        var _btnTitleReplace: String = "REPLACE \(selectedIndexes.count) photos"
        
        if selectedIndexes.count == 1 {
            _title = "Replace this Photo"
            _message = "Do you want to replace this photo by new one or just delete it?"
            _btnTitleDelete = "DELETE this photo"
            _btnTitleReplace = "REPLACE this photo"
        }
        
        let alert = UIAlertController(
            title: _title,
            message: _message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "No, Cancel!", style: .default, handler: { (action: UIAlertAction) in
            self.resetSelectionForCollectionView()
        }))
        
        alert.addAction(UIAlertAction(title: _btnTitleReplace, style: .default, handler: { (action: UIAlertAction) in
            self.replacePhotosOfCollectionFromSelection()
        }))
        
        alert.addAction(UIAlertAction(title: _btnTitleDelete, style: .default, handler: { (action: UIAlertAction) in
            self.deletePhotosOfCollectionBySelection()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func refreshCollectionView() {
        
        if isDataAvailable() {
            
            photoCollectionView?.reloadData()
            
        } else {
            
            toggleCollectionViewInfoLabel(true)
            
        }
    }
    
    func isDataAvailable() -> Bool {
        
        return appDelegate.photoQueue.count > 0
    }
}

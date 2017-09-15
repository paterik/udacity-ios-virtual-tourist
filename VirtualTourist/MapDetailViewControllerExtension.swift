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
    
        photoDataObjects.removeAll()
        photoCellIndexRefreshed = 0
        
        // reset async photo download/processing queue
        appDelegate.photoQueue.removeAll()
        appDelegate.photoQueueImagesDownloaded = 0
        
        // reload collectionView to show/refresh items
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
    
    func setCollectionViewInfoLabelProcessing() {
    
        mapNoPhotosInfoLabel.text = mapMsgPhotosInDownload
        mapNoPhotosInfoLabel.backgroundColor = UIColor(netHex: 0x23A7CE)
    }
    
    func setCollectionViewInfoLabelNoData() {
        
        mapNoPhotosInfoLabel.text = mapMsgNoPhotosAvailable
        mapNoPhotosInfoLabel.backgroundColor = UIColor(netHex: 0xEC2C61)
    }
    
    func loadPhotosForCollectionView(_ notification: NSNotification?) {
        
        getPhotosForCollectionByPin() {
                
            (photos, success, error) in
                
            if success == true {
                    
                if photos != nil {
                        
                    self.photoDataObjects = photos!
                    
                    //
                    // mode 1: normal loading of persisted photo stack
                    //
                    
                    if notification == nil {
                        
                        // remove complete placeholder imageStack
                        self.appDelegate.photoQueue.removeAll()
                        for (index, photo) in self.photoDataObjects.enumerated() {
                            self.appDelegate.photoQueue.append(photo.convertToPhotoQueueObject(index))
                        }
                    
                    //
                    // mode 2: event based refresh loading of new persisted photo sack
                    //
                        
                    } else {
                        
                        self.setCollectionViewInfoLabelProcessing()
                        
                        // determine the maximal photo stack count available from last api request
                        self.appDelegate.photoQueueImagesAvailable = self.getMaxIndexOfCurrentDownloadSession(notification)
                        self.appDelegate.photoQueueImagesDownloaded = 0
                        
                        // iterate through complete image stack to fetch the latest downloaded image
                        for (queueIndex, queueItem) in self.appDelegate.photoQueue.enumerated() {
                        
                            // count current download stack position to predict download finish line
                            if queueItem._metaDownloadCompleted! == true { self.appDelegate.photoQueueImagesDownloaded += 1 }
                            
                            // try to fetch a photo which was downloaded but not presented as cell
                            if  queueItem._metaDownloadCompleted! == true &&
                                queueItem._metaDownloadAsCellProcessed == false {
                                
                                var queueObjectToUpdate = self.appDelegate.photoQueue[queueIndex]
                                    queueObjectToUpdate._metaDownloadAsCellProcessed = true
                                
                                self.appDelegate.photoQueue[queueIndex] = queueObjectToUpdate
                                
                                let qTime: Int = self.getSecondsBetweenTwoDates(queueItem._metaQueueCreatedAt!, queueItem._metaQueueUpdatedAt!)
                                let qSizeRawInKb = queueItem._metaDataSizeRaw!.rounded()
                                let qSizeThumbInKb = queueItem._metaDataSizeConverted!.rounded()
                                
                                if self.appDebugMode == true {
                                    print ("Queue/Cell: \(queueIndex)/\(self.appDelegate.photoQueueImagesAvailable) updated => [q_raw: \(qSizeRawInKb)kb, q_thumb: \(qSizeThumbInKb)kb, q_time: \(qTime)s ] #\(self.appDelegate.photoQueueImagesDownloaded)")
                                }
                            }
                        }
                        
                        // check queue final state and cleanUp cache/placeholder fragments
                        if self.appDelegate.photoQueueImagesDownloaded == self.appDelegate.photoQueueImagesAvailable - 1 {
                        
                            self.pin.isDownloading = false
                            self.toggleRefreshCollectionButton(true)
                            self.toggleCollectionViewInfoLabel(false)
                        }
                    }
                }
                
                self.refreshCollectionView()
                    
            } else {
                    
                if self.appDebugMode { print (error ?? "unknown image handler problem") }
            }
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
    
    func cleanUpCollectionViewCache() {
    
        if self.appDebugMode == true {
            print ("===> cleanUp photoQueue <===")
        }
        
        for (index, photo) in appDelegate.photoQueue.enumerated() {
            if photo._metaDownloadCompleted == false {
                if index <= appDelegate.photoQueue.count {
                    appDelegate.photoQueue.remove(at: index)
                }
            }
        }
    }
    
    func loadViewAdditions() {
        
        setCollectionViewInfoLabelNoData()
        
        btnRefreshPhotosForThisLocation.isEnabled = true
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
    
    func toggleCollectionViewInfoLabel(_ enabled: Bool) {
        
        mapNoPhotosInfoLabel.isEnabled = enabled
        mapNoPhotosInfoLabel.isHidden = !enabled
    }
    
    func toggleRefreshCollectionButton(_ enabled: Bool) {
        
        btnRefreshPhotosForThisLocation.isEnabled = enabled
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

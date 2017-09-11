//
//  MapViewControllerExtension.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 27.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreStore

extension MapViewController {

    //
    // MARK: MapView Helper Methods
    //
    
    func setupUIMap() {
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.mapAddPin(_:)))
        longPress.minimumPressDuration = mapLongPressDuration
        
        mapView.addGestureRecognizer(longPress)
        mapView.delegate = self
    }

    func loadMapRegion() {
        
        mapViewRegion = CoreStore.fetchOne(From<MapRegion>())
        if mapViewRegion == nil {
            
            _ = try? CoreStore.perform(
                synchronous: { (transaction) in
                    
                    mapViewRegion = transaction.create(Into<MapRegion>())
                    mapViewRegion?.region = mapView.region
                }
            )
            
            mapViewRegion = CoreStore.fetchOne(From<MapRegion>())
        }
        
        mapViewRegionObjectId = mapViewRegion!.objectID
        mapView.region = mapViewRegion!.region
    }
    
    func saveMapRegion() {
        
        CoreStore.perform(
            asynchronous: { (transaction) -> MapRegion in
                self.mapViewRegion = transaction.fetchExisting(self.mapViewRegionObjectId!)!
                self.mapViewRegion?.region = self.mapView.region
                
                return self.mapViewRegion!
                
            },  success: { (transactionRegion) in
            
                self.mapViewRegion = CoreStore.fetchExisting(transactionRegion)!
                self.mapViewRegionObjectId = self.mapViewRegion?.objectID // just to be sure ;)
                if self.appDebugMode == true { print ("--- mapRegionObjID: \(self.mapViewRegionObjectId!) updated ---") }
            
            },  failure: { (error) in print (error) }
        )
    }
    
    func loadMapAnnotations() {
        
        if let mapViewPins = _getAllPins() {
            mapView.addAnnotations(mapViewPins)
        }
    }
    
    func loadMapAdditions() {
        
        mapEditModeInfoLabel.backgroundColor = UIColor(netHex: 0xEC2C61)
        mapEditModeInfoLabel.textColor = UIColor(netHex: 0xFFFFFF)
        mapEditModeInfoLabel.textAlignment = .center
        mapEditModeInfoLabel.text = "Now Tap Pins to Delete"
        mapEditModeInfoLabel.isEnabled = false
        mapEditModeInfoLabel.isHidden = true
        
        view.addSubview(mapEditModeInfoLabel)
        
        mapEditModeInfoLabel.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.width.equalTo(self.view)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
    }
    
    func handleLastPhotoTransfered(_ notification: NSNotification?) {
        
        if _pinLastAdded == nil || notification == nil { return }
        
        if let userInfo = notification!.userInfo as? [String: Bool]
        {
            _pinLastAdded!.isDownloading = true
            
            if let completed = userInfo["completed"] {
                if completed == true {
                    
                    _pinLastAdded!.isDownloading = !completed
                }
            }
        }
    }
    
    func _getAllPins() -> [Pin]? {
        
        return CoreStore.fetchAll(From<Pin>())
    }
    
    func _deletePin (_ targetPin: Pin!)  {
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                
                transaction.deleteAll(
                    From<Pin>(),
                    Where("metaHash", isEqualTo: targetPin.metaHash)
                )
            },
            success: { _ in
                self.mapView.removeAnnotation(targetPin)
                self._pinSelected = nil
                if self.appDebugMode == true {
                    print ("[_DEV_] \(targetPin.coordinate) deleted from persistance layer!")
                }
                
            },
            failure: { (error) in
                self._handleErrorAsSimpleDialog("Error", error.localizedDescription)
                return
            }
        )

        // check that corresponding photos deleted also
        if let photos = CoreStore.fetchAll(From<Photo>()) {
            if self.appDebugMode == true {
                print ("===============================")
                print ("\(photos.count) still available")
            }
        }
    }
    
    func _deleteAllPins() {
        
        let numOfCurrentPins = CoreStore.fetchAll(From<Pin>())?.count
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                transaction.deleteAll(From<Pin>())
            },
            completion: { _ in
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                if self.appDebugMode == true {
                    print ("[_DEV_] all \(numOfCurrentPins!) previously saved pins deleted from persitance layer")
                }
            }
        )
    }
}

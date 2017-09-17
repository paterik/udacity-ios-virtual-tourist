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
import YNDropDownMenu

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
    
    /*
     * handle delegate commands from other view (e.g. menu calls)
     */
    func handleDelegateCommand(
        _ command: String) {
        
        if appDebugMode { print ("_received command: \(command)") }
        
        if command == "showSettingsForApp" {
            appMenu!.hideMenu()
        }
        
        if command == "showStatisticsForApp" {
            appMenu!.hideMenu()
        }
    }
    
    func setupUIMenu() {
    
        let menuViews = Bundle.main.loadNibNamed("MapMainMenu", owner: nil, options: nil) as? [MapMainMenu]
        
        if let _menuViews = menuViews {
            
            let backgroundView = UIView()
                backgroundView.backgroundColor = .black
            
            let _menuView = _menuViews[0] as MapMainMenu
                _menuView.delegate = self
            
            appMenu = YNDropDownMenu(
                frame: CGRect(x: 0, y: 28, width: UIScreen.main.bounds.size.width, height: 38),
                dropDownViews: [_menuView],
                dropDownViewTitles: [""] // no title(s) required
            )
            
            appMenu!.setImageWhen(
                normal:   UIImage(named: "icnMenu_v1"),
                selected: UIImage(named: "icnMenuCancel_v1"),
                disabled: UIImage(named: "icnMenu_v1")
            )
            
            appMenu!.setLabelColorWhen(normal: .black, selected: UIColor(netHex: 0xFFA409), disabled: .gray)
            appMenu!.setLabelFontWhen(normal: .systemFont(ofSize: 12), selected: .boldSystemFont(ofSize: 12), disabled: .systemFont(ofSize: 12))
            appMenu!.backgroundBlurEnabled = true
            appMenu!.bottomLine.isHidden = false
            
            appMenu!.blurEffectView = backgroundView
            appMenu!.blurEffectViewAlpha = 0.7
            appMenu!.alwaysSelected(at: 0)
            
            self.view.addSubview(appMenu!)
            
            appMenu!.snp.makeConstraints { (make) -> Void in
                
                make.bottom.equalTo(mapView.snp.top).offset( 203 )
                make.height.equalTo( 128 )
                make.width.equalTo( self.view )
            }
        }
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
                if self.appDebugMode { print ("--- mapRegionObjID: \(self.mapViewRegionObjectId!) updated ---") }
            
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
            make.height.equalTo( 50 )
            make.width.equalTo(self.view)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
    
        mapLoadingBar.isEnabled = true
        mapLoadingBar.isHidden = false
        
        view.addSubview(mapLoadingBar)
        
        _initProgressBar()
    }
    
    func _initProgressBar() {
    
        mapLoadingBar.backgroundColor = UIColor(netHex: 0x262626)
        mapLoadingBar.isEnabled = true
        mapLoadingBar.isHidden = false
        
        self.mapLoadingBar.snp.remakeConstraints { (make) -> Void in
            
            make.bottom.equalTo(mapView.snp.top).offset( 10 )
            make.height.equalTo( 5 )
            make.width.equalTo( 0 )
        }
    }
    
    func _deinitProgressBar() {
        
        appDelegate.photoQueueDownloadIsActive = false
        
        mapLoadingBar.isEnabled = false
        mapLoadingBar.isHidden = true
        
        progressCounter = 0
        progressCurrentPerc = 0
        progressCurrentWidth = 0
        
        _initProgressBar()
    }
    
    func handleProgressBar(_ notification: NSNotification?) {
    
        if let userInfo = notification!.userInfo as? [String: Int]
        {
            if let indexMax = userInfo["indexMax"] {
                
                progressCounter += 1
                progressMaxWidth = Float(self.view.layer.frame.width)
                progressCurrentPerc = Float(progressCounter * 100 / indexMax)
                if progressCurrentPerc > 0 {
                    
                    appDelegate.photoQueueDownloadIsActive = true
                    
                    progressCurrentWidth = progressMaxWidth / 100 * progressCurrentPerc
                    self.mapLoadingBar.snp.remakeConstraints { (make) -> Void in
                        
                        make.height.equalTo( 10 )
                        make.width.equalTo( progressCurrentWidth )
                        make.bottom.equalTo(mapView.snp.top).offset( 10 )
                        
                        if progressCurrentPerc == 100 {
                            
                            self.mapLoadingBar.backgroundColor = UIColor(netHex: 0x1ABC9C)
                            
                            let _ = Timer.scheduledTimer(
                                timeInterval: 0.675,
                                target: self,
                                selector:  #selector(MapViewController._deinitProgressBar),
                                userInfo: nil,
                                repeats: false
                            )
                        }
                    }
                    
                    if appDebugMode {
                        print ("===> \(progressCounter)/\(indexMax) <=== \(self.view.layer.frame.width) : \(progressCurrentPerc)")
                    }
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
                if self.appDebugMode {
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
            if self.appDebugMode {
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
                if self.appDebugMode {
                    print ("[_DEV_] all \(numOfCurrentPins!) previously saved pins deleted from persitance layer")
                }
            }
        )
    }
}

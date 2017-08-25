//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 13.04.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import MapKit
import CoreStore
import YNDropDownMenu

class MapViewController: BaseController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var pinSelected:Pin!
    var pinLastAdded:Pin? = nil
    var mapViewRegion:MapRegion?
    
    override func viewDidLoad() {
        
        setupMap()
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    func loadMapRegion() {
    
        print ("loadMapRegion called ...")
        
        if mapViewRegion == nil {
            mapViewRegion = MapRegion()
            mapViewRegion?.region = mapView.region
            
        } else {
            mapViewRegion!.region = mapView.region
        }
        
         CoreStore.beginAsynchronous { (transaction) -> Void in
            
            let mapRegion = transaction.create(Into(MapRegion))
            
            transaction.commit { (result) -> Void in
                switch result {
                case .Success(let hasChanges): print("success!")
                case .Failure(let error): print(error)
                }
            }
        }
        
    }
    
    func saveMapRegion() {}
    
    func setupMap() {
    
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addPin(_:)))
            longPress.minimumPressDuration = 1.0
        
        mapView.addGestureRecognizer(longPress)
        
        loadMapRegion()
    }
    
    func addPin(_ gestureRecognizer: UIGestureRecognizer) {
        
        let locationInMap = gestureRecognizer.location(in: mapView)
        let coordinate:CLLocationCoordinate2D = mapView.convert(locationInMap, toCoordinateFrom: mapView)
        
        print (coordinate)
        
    }
}


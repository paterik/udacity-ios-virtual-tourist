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
    
    let mapLongPressDuration = 1.250
    let mapPinIdentifier = "Pin"
    let mapPinImageName = "icnMapPin_v1"
    
    // let progressView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 50))
    
    var _pinSelected:Pin!
    var _pinLastAdded:Pin? = nil
    
    var mapViewPin:Pin?
    var mapViewRegion:MapRegion?
    var mapViewRegionObjectId:NSManagedObjectID? = nil
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        mapSetup()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
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
    
    //
    // MARK: MapView Delegates
    //
    
    func mapView(
       _ mapView: MKMapView,
         regionDidChangeAnimated animated: Bool) {
        
        saveMapRegion()
    }

    func mapView(
       _ mapView: MKMapView,
         viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil }
        
        var annotationView: MKAnnotationView
            
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: mapPinIdentifier) {
            
            dequeuedView.annotation = annotation
            annotationView = dequeuedView
                
        } else {
                
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: mapPinIdentifier)
            annotationView.image = UIImage(named: mapPinImageName)
            annotationView.canShowCallout = false
            annotationView.isDraggable = false
        }
            
        return annotationView
    }
    
    /*func setProgress(_ progress: CGFloat) {
        let fullWidth: CGFloat = 200
        let newWidth = progress/100*fullWidth
        UIView.animate(withDuration: 1.5) {
            self.progressView.frame.size = CGSize(width: newWidth, height: self.progressView.frame.height)
        }
    }*/
    
    func mapSetup() {
    
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.mapAddPin(_:)))
            longPress.minimumPressDuration = mapLongPressDuration
        
        mapView.addGestureRecognizer(longPress)
        mapView.delegate = self
        
        // progressView.backgroundColor = .blue
        // mapView.addSubview(progressView)
        
         loadMapRegion()
        _deleteAllPins() // just for debug_&_dev reasons
    }
    
    func mapAddPin(_ gestureRecognizer: UIGestureRecognizer) {
        
        let locationInMap = gestureRecognizer.location(in: mapView)
        let coordinate:CLLocationCoordinate2D = mapView.convert(locationInMap, toCoordinateFrom: mapView)
        
        switch gestureRecognizer.state {
            
            case UIGestureRecognizerState.began:
                
                CoreStore.perform(
                    
                    asynchronous: { (transaction) -> Pin in
                        
                        self.mapViewPin = transaction.create(Into<Pin>())
                        self.mapViewPin?.coordinate = coordinate
                        
                        return self.mapViewPin!
                        
                    },  success: { (transactionPin) in
                        
                        self.mapViewPin = CoreStore.fetchExisting(transactionPin)!
                        self.mapView.addAnnotation(self.mapViewPin!)
                        
                        if self.appDebugMode == true { print ("--- mapMapPinObject created successfully ---") }
                    
                    },  failure: { (error) in print (error) }
                    
                )
            
            case UIGestureRecognizerState.ended:
                let numOfPins = CoreStore.fetchAll(From<Pin>())?.count
                print ("pin #\(numOfPins!) set successfully done at \(coordinate)")
            
            default: return
        }
    }
    
    func _deleteAllPins() {
        
        let numOfCurrentPins = CoreStore.fetchAll(From<Pin>())?.count
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                transaction.deleteAll(From<Pin>())
            },
            completion: { _ in
                print ("[_DEV_] all \(numOfCurrentPins!) previously saved pins deleted from persitance layer")
            }
        )
    }
}


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
    @IBOutlet weak var btnEditModeItem: UIBarButtonItem!
    
    let mapLongPressDuration = 0.875
    let mapPinIdentifier = "Pin"
    let mapPinImageName = "icnMapPin_v1"
    
    var _pinSelected:Pin!
    var _pinLastAdded:Pin? = nil
    
    var editMode:Bool = false
    
    var mapViewPin:Pin?
    var mapViewPins:[Pin]?
    var mapViewRegion:MapRegion?
    var mapViewRegionObjectId:NSManagedObjectID? = nil
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        mapSetup()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func toggleEditMode(_ sender: AnyObject) {
        
        if editMode {
            editMode = false
            btnEditModeItem.title = "Edit"
        } else {
            editMode = true
            btnEditModeItem.title = "Done"
        }
    }
    
    func loadMapAnnotations() {
    
        if let mapViewPins = _getAllPins() {
            mapView.addAnnotations(mapViewPins)
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
    
    func mapView(
       _ mapView: MKMapView,
         didSelect view: MKAnnotationView) {
        
        let annotation = view.annotation as! Pin
           _pinSelected = annotation
        
        if !editMode {
            print ("api call not implemented yet ...")
            return
        }
        
        print ("*** \(_pinSelected.objectID)")
        print ("*** \(annotation.objectID)")
        print ("--- --------------------------------------------------------------------------------------------------")
        
        let alert = UIAlertController(title: "Delete Pin", message: "Do you really want to remove this pin?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No, Cancel!", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
                //self._deletePin(annotation)
                
                _ = try? CoreStore.perform(
                    synchronous: { (transaction) in
                        
                        transaction.delete(self._pinSelected)
                        self.mapView.removeAnnotation(self._pinSelected)
                        self._pinSelected = nil
                })
                
            })
        )
        
        present(alert, animated: true, completion: nil)
    }

    
    func mapSetup() {
    
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.mapAddPin(_:)))
            longPress.minimumPressDuration = mapLongPressDuration
        
        mapView.addGestureRecognizer(longPress)
        mapView.delegate = self
        
        btnEditModeItem.title = "Edit"
        
        loadMapRegion()
        loadMapAnnotations()
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
                    
                    },  failure: { (error) in
                        self._handlerErrorAsSimpleDialog("Error Add Pin", error.localizedDescription)
                        
                        return
                    }
                )
            
            case UIGestureRecognizerState.ended:
                let numOfPins = CoreStore.fetchAll(From<Pin>())?.count
                if self.appDebugMode == true { print ("pin #\(numOfPins!) set successfully done at \(coordinate)") }
            
            default: return
        }
    }
    
    func _getAllPins() -> [Pin]? {
        
        return CoreStore.fetchAll(From<Pin>())
    }

    func _deletePin (_ targetPin: Pin!)  {
    
        
        print ("*** \(targetPin.objectID)")
        print ("--- --------------------------------------------------------------------------------------------------")

        _ = try? CoreStore.perform(
            synchronous: { (transaction) in
                
                transaction.delete(targetPin)
                self.mapView.removeAnnotation(targetPin)
                self._pinSelected = nil
        })
        
        /*CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                transaction.delete(targetPin)
            },
            success: { _ in
                self.mapView.removeAnnotation(targetPin)
                self._pinSelected = nil
                if self.appDebugMode == true {
                    print ("[_DEV_] \(targetPin.coordinate) deleted from persistance layer!")
                }
                
            },
            failure: { (error) in
                self._handlerErrorAsSimpleDialog("Error Deleting Single Pin", error.localizedDescription)
                return
            }
        )*/
    }
    
    func _deleteAllPins() {
        
        let numOfCurrentPins = CoreStore.fetchAll(From<Pin>())?.count
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                transaction.deleteAll(From<Pin>())
            },
            completion: { _ in
                if self.appDebugMode == true {
                    print ("[_DEV_] all \(numOfCurrentPins!) previously saved pins deleted from persitance layer")
                }
            }
        )
    }
}


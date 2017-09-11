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
import SnapKit

class MapViewController: BaseController, MKMapViewDelegate {

    //
    // MARK: IBOutlet Variables
    //
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnEditModeItem: UIBarButtonItem!
    
    //
    // MARK: Class Constants
    //
    
    let mapLongPressDuration = 0.875
    let mapPinIdentifier = "Pin"
    let mapPinPersistedImageName = "icnMapPin_v1"
    let mapPinNewAddedImageName = "icnMapPin_v2"
    let mapPinIncompleteImageName = "icnMapPin_v3"
    let mapEditModeInfoLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    let flickrClient = FlickrClient.sharedInstance
    
    //
    // MARK: Class Variables
    //
    
    var _pinSelected:Pin!
    var _pinLastAdded:Pin? = nil
    
    var mapViewPin:Pin?
    var mapViewPins:[Pin]?
    var mapViewRegion:MapRegion?
    var mapViewRegionObjectId:NSManagedObjectID? = nil
    var mapEditMode:Bool = false
    
    //
    // MARK: UIViewController Overrides
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIMap()
        
        loadMapRegion()
        loadMapAnnotations()
        loadMapAdditions()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MapViewController.handleLastPhotoTransfered),
            name: NSNotification.Name(rawValue: appDelegate.pinPhotoDownloadedNotification),
            object: nil
        )
    }
    
    //
    // MARK: IBAction Methods
    //
    
    @IBAction func toggleEditMode(_ sender: AnyObject) {
        
        btnEditModeItem.image = UIImage(named: "icnLock_v1")
        if !mapEditMode {
            btnEditModeItem.image = UIImage(named: "icnUnlock_v1")
        }
        
        mapEditModeInfoLabel.isEnabled = !mapEditMode
        mapEditModeInfoLabel.isHidden = mapEditMode
        
        mapEditMode = !mapEditMode
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
            annotationView.image = UIImage(named: mapPinNewAddedImageName)
            annotationView.canShowCallout = false
            annotationView.isDraggable = false
            
            let _photoAnnotation = annotationView.annotation as! Pin
            if  _photoAnnotation.photos.count > 0 {
                 annotationView.image = UIImage(named: mapPinPersistedImageName)
            }
        }
        
        return annotationView
    }
    
    func mapView(
       _ mapView: MKMapView,
         didSelect view: MKAnnotationView) {
        
        let annotation = view.annotation as! Pin
           _pinSelected = annotation
        
        if !mapEditMode {
            
            performSegue(withIdentifier: "locationDetail", sender: self)
            
        } else {
        
            let alert = UIAlertController(title: "Delete Pin", message: "Do you really want to remove this pin?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "No, Cancel!", style: .default, handler: nil))
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
                    self._deletePin(self._pinSelected)
            }))
            
            present(alert, animated: true, completion: nil)
        }
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
                        self._pinLastAdded = self.mapViewPin!
                        
                        if self.appDebugMode == true { print ("--- mapMapPinObject created successfully ---") }
                    
                    },  failure: { (error) in
                        
                        self._pinLastAdded = nil // reset last added pin holder, prevent photo preload on error
                        self._handleErrorAsSimpleDialog("Error", error.localizedDescription)
                        
                        return
                    }
                )
            
            case UIGestureRecognizerState.ended:
                
                //
                // fetch download of pin related photos as quick as possible if last pin was set successfully
                //
                if  _pinLastAdded !== nil {
                    
                    flickrClient.getImagesByMapPin (_pinLastAdded!) {
                        
                        (success, error) in
                        
                        if success == false || error != nil {
                            
                            // allow error to be shown (even in production mode)
                            self._handleErrorAsSimpleDialog("Error", error?.description ?? "unkown error occurred")
                        }
                    }
                    
                    if appDebugMode == true {
                        
                        let numOfPins = CoreStore.fetchAll(From<Pin>())?.count
                        print ("pin #\(numOfPins!) set successfully done at \(coordinate)")
                    }
                }
            
            default: return
        }
    }
    
    //
    // MARK: Segue/Navigation
    //
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "locationDetail" {
            
            mapView.deselectAnnotation(_pinSelected, animated: false)
            let controller = segue.destination as! MapDetailViewController
                controller.pin = _pinSelected
        }
    }
}


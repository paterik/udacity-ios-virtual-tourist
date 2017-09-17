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
import SnapKit

class MapViewController: BaseController, MKMapViewDelegate {

    //
    // MARK: IBOutlet Variables
    //
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnEditModeItem: UIBarButtonItem!
    @IBOutlet weak var btnAppMenu: UIBarButtonItem!
    
    //
    // MARK: Class Special Constants
    //
    
    let flickrClient = FlickrClient.sharedInstance
    
    //
    // MARK: Class Basic Constants
    //
    
    let mapPinIdentifier = "Pin"
    let mapPinDetailIdentifier = "locationDetail"
    let mapPinPersistedImageName = "icnMapPin_v1"
    let mapPinIncompleteImageName = "icnMapPin_v3"
    let mapLongPressDuration = 0.875
    
    //
    // MARK: Class Variables
    //
    
    var _pinSelected: Pin!
    var _pinLastAdded: Pin? = nil
    var mapViewPin: Pin?
    var mapViewPins: [Pin]?
    var mapViewRegion: MapRegion?
    var mapViewRegionObjectId: NSManagedObjectID? = nil
    var mapEditMode: Bool = false
    
    var progressCounter: Int = 0
    var progressCurrentPerc: Float = 0.0
    var progressMaxWidth: Float = 0.0
    var progressCurrentWidth: Float = 0.0
    
    //
    // MARK: UIViewController Overrides
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIMap()
        
        loadMapRegion()
        loadMapAdditions()
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(MapViewController._handleProgressBar(_:)),
            name: NSNotification.Name(rawValue: appDelegate.pinPhotoDownloadedNotification),
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear( animated )

        loadMapAnnotations()
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
            annotationView.image = UIImage(named: mapPinPersistedImageName)
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
    
    func toggleMapControls(_ enabled: Bool) {
        
        btnAppMenu.isEnabled = enabled
        btnEditModeItem.isEnabled = enabled
    }
    
    func mapAddPin(_ gestureRecognizer: UIGestureRecognizer) {
        
        // wait for last download completion before adding new pins
        if appDelegate.photoQueueDownloadIsActive == true { return }
        
        // disable statistic-/pinLock button while downloading
        toggleMapControls(false)
        
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
                        
                        if self.appDebugMode { print ("--- mapMapPinObject created successfully ---") }
                    
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
                    
                    flickrClient.getImagesByMapPin (_pinLastAdded!, nil) {
                        
                        (success, error) in
                        
                        if success == false || error != nil {
                            
                            // allow error to be shown (even in production mode)
                            self._handleErrorAsSimpleDialog("Error", error?.description ?? "unkown error occurred")
                        }
                    }
                    
                    if appDebugMode {
                        
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
        
        if segue.identifier == mapPinDetailIdentifier {
            
            mapView.deselectAnnotation(_pinSelected, animated: false)
            let controller = segue.destination as! MapDetailViewController
                controller.pin = _pinSelected
        }
    }
}


//
//  MapDetailViewController.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 27.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import MapKit
import CoreStore

class MapDetailViewController: BaseController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //
    // MARK: IBOutlet Variables
    //
    
    @IBOutlet weak var btnBackToMapItem: UIBarButtonItem!
    @IBOutlet weak var miniMapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var lblNoImagesFound: UILabel!
    @IBOutlet weak var btnRefreshPhotosForThisLocation: UIBarButtonItem!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    //
    // MARK: Class Constants
    //
    
    let mapPinIdentifier = "MiniMapPin"
    let mapPinImageName = "icnMapPin_v2"
    let collectionViewCellIdentifier = "flickrCell"
    let flickrClient = FlickrClient.sharedInstance
    
    //
    // MARK: Class Variables
    //
    
    var pin: Pin!
    var photoDataObjects = [Photo]()
    var photoObjects = [PhotoCellObject]()
    
    //
    // MARK: UIViewController Overrides
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        mapSetup()
        collectionViewSetup()
    }
    
    override func willRotate(
        to toInterfaceOrientation: UIInterfaceOrientation,
        duration: TimeInterval) {
        
        photoCollectionView!.collectionViewLayout.invalidateLayout()
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
            imagePreview: UIImagePreview
        )
    }
    
    func collectionViewSetup() {
    
        photoCollectionView.isHidden = false
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        lblNoImagesFound.isHidden = true
        
        getPhotosForCollectionByPin(pin) {
        
            (photos, success, error) in
        
            if success! == true {
                
                self.photoDataObjects = photos!
                for photo in self.photoDataObjects {
                    self.photoObjects.append(self.convertPhotoToPhotoCellObject(photo))
                }
                
                self.refreshCollectionView()
                
            } else {
                
                if self.appDebugMode { print (error ?? "unknown image handler problem") }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    //
    // MARK: IBAction Methods
    //
    
    @IBAction func btnBackToMapAction(_ sender: Any) {
    
        dismiss(animated: true, completion: nil)
    }
    
    //
    // MARK: CollectionView Delegates
    //
    
    func collectionView(
       _ collectionView: UICollectionView,
         numberOfItemsInSection section: Int) -> Int {
        
        return photoObjects.count
    }
    
    func collectionView(
       _ collectionView: UICollectionView,
         cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: collectionViewCellIdentifier,
            for: indexPath) as! FlickrCell
        
        let photo = photoObjects[indexPath.row]
        
        //
        // handle image for corresponding cell, try to load preview image first
        // if no preview image found, take origin photo instead ... failsafe to
        // sample/default image
        //
        
        if photo.imagePreview != nil {
            
            cell.imageView.image = photo.imagePreview
            if appDebugMode { print ("using preview image for cel #\(indexPath.row)") }
            
        } else if photo.imageOrigin != nil {
            
            cell.imageView.image = photo.imageOrigin
            if appDebugMode { print ("using origin image for cel #\(indexPath.row)") }
            
        } else {
            
            cell.imageView.image = UIImage(named: "sample_image")
            if appDebugMode { print ("using sample image for cel #\(indexPath.row)") }
            
        }

        cell.activityIndicator.stopAnimating()
        cell.activityIndicator.isHidden = true
        
        return cell
    }
    
    func collectionView(
       _ collectionView: UICollectionView,
         layout collectionViewLayout: UICollectionViewLayout,
         sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        var collectionCellWidth: CGFloat!
        var collectionCellHeight: CGFloat!
        var collectionCellPadding: CGFloat = 12.0
        var collectionCellSpacing: CGFloat = 8.0
        var numberOfCellInRow: CGFloat = 2.0
        
        if UIApplication.shared.statusBarOrientation != UIInterfaceOrientation.portrait {
            numberOfCellInRow = 3.0
            collectionCellPadding = 8.0
            collectionCellSpacing = 4.0
        }
        
        collectionCellWidth = (view.frame.width / numberOfCellInRow) - collectionCellPadding
        collectionCellHeight = collectionCellWidth
        
        flowLayout.itemSize = CGSize(width: collectionCellWidth, height: collectionCellHeight)
        flowLayout.minimumInteritemSpacing = collectionCellSpacing
        flowLayout.minimumLineSpacing = collectionCellSpacing
        
        return CGSize(
            width: collectionCellWidth,
            height: collectionCellHeight
        );
    }
    
    //
    // MARK: MapView Delegates
    //
    
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
    
    //
    // MARK: MapView Helper Methods
    //
    
    func mapSetup() {
        
        // @todo (v1.0.n): move this as property pack deep inside the corresponding PIN entity
        let pinCenter = CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        let pinRegion = MKCoordinateRegion(center: pinCenter, span: MKCoordinateSpan(latitudeDelta: 0.375, longitudeDelta: 0.375))

        miniMapView.delegate = self
        miniMapView.setRegion(pinRegion, animated: true)
        miniMapView.setCenter(pin.coordinate, animated: true)
        miniMapView.addAnnotation(pin)
    }
    
    //
    // IBAction Methods
    //
    
    @IBAction func btnReloadPhotoCollection(_ sender: Any) {
        
        let alert = UIAlertController(
            title: "Delete Collection",
            message: "Do you really want to refresh this collection by loading new images?", preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "No, Cancel!", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
            
            self.deletePhotosOfCollectionByPin(self.pin) {
                
                (success, error) in
                
                if success! == true {
                    
                    self.flickrClient.getImagesByMapPin (self.pin!) {
                        
                        (success, error) in
                        
                        if success == false {
                            
                            self._handleErrorAsSimpleDialog("Error", error?.description ?? "unkown error occurred")
                        
                        } else {
                        
                            self.collectionViewSetup()
                        }
                    }
                    
                } else {
                
                    if self.appDebugMode { print (error ?? "unknown image deletion problem") }
                
                }
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
}

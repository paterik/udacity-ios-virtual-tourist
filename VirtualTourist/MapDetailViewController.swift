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
    @IBOutlet weak var btnRefreshPhotosForThisLocation: UIBarButtonItem!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    //
    // MARK: Class Constants
    //
    
    let mapPinIdentifier = "MiniMapPin"
    let mapPinImageName = "icnMapPin_v2"
    let mapNoPhotosInfoLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
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
        
        setupUIMap()
        setupUICollectionView()
        
        loadViewAdditions()
        loadPhotosForCollectionView(nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MapDetailViewController.loadPhotosForCollectionView),
            name: NSNotification.Name(rawValue: appDelegate.pinPhotoDownloadedNotification),
            object: nil
        )
    }
    
    override func willRotate(
        to toInterfaceOrientation: UIInterfaceOrientation,
        duration: TimeInterval) {
        
        photoCollectionView!.collectionViewLayout.invalidateLayout()
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
        )
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
    // MARK: IBAction Methods
    //
    
    @IBAction func btnBackToMapAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnReloadPhotoCollection(_ sender: Any) {
        
        // deactivate reload collection button
        toggleRefreshCollectionButton(false)
        
        let alert = UIAlertController(
            title: "Delete Collection",
            message: "Do you really want to refresh this collection by loading new images?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "No, Cancel!", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
            
            self.deletePhotosOfCollectionByPin(self.pin) {
                
                (success, error) in
                
                // delete successfully done?
                if error == nil {
                    
                    // load new imageSet using flickr api call
                    self.flickrClient.getImagesByMapPin (self.pin!) {
                        
                        (success, error) in
                        
                        if success == false || error != nil {
                            
                            self._handleErrorAsSimpleDialog("Error", error?.description ?? "unkown error occurred")
                        
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

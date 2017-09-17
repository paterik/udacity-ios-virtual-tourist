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
    // MARK: Class Special Constants
    //
    
    let flickrClient = FlickrClient.sharedInstance
    
    //
    // MARK: Class Basic Constants
    //
    
    let mapPinIdentifier = "MiniMapPin"
    let mapPinImageName = "icnMapPin_v2"
    let mapNoPhotosInfoLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    let mapMsgNoPhotosAvailable = "There are no photos available for this location"
    let collectionViewCellIdentifier = "flickrCell"
    let cellPhotoImagePlaceholder = "imgPhotoPlaceholder_v1"
    let cellPhotoImageAlphaForSelected: CGFloat = 0.475
    
    //
    // MARK: Class Variables
    //
    
    var pin: Pin!
    var selectedIndexes = [IndexPath]()
    
    //
    // MARK: UIViewController Overrides
    //

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIMap()
        setupUICollectionView()
        
        loadViewAdditions()
        loadPhotosForCollectionView(nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(MapDetailViewController.loadPhotosForCollectionView(_:)),
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
        
        return appDelegate.photoQueue.count
    }
    
    func collectionView(
       _ collectionView: UICollectionView,
         cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: collectionViewCellIdentifier,
            for: indexPath) as! FlickrCell
        
        let photoQueueItem = appDelegate.photoQueue[indexPath.row]
        
        //
        // handle image for corresponding cell, try to load preview image first
        // if no preview image found, take origin photo instead ... failsafe to
        // sample/default image (will be simplified in future version)
        //
        
        cell.activityIndicator.stopAnimating()
        cell.activityIndicator.isHidden = true
        
        if  photoQueueItem._metaDownloadCompleted == false ||
           (photoQueueItem._imageJPEGRaw == nil && photoQueueItem._imageJPEGConverted == nil) {
        
            cell.imageView.image = UIImage(named: cellPhotoImagePlaceholder)
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.isHidden = false
        
        } else {
            
            cell.imageView.image = getCellImageForPhoto(photoQueueItem)
        }
        
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
        var numberOfCellInRow: CGFloat = 3.0
        
        if UIApplication.shared.statusBarOrientation != UIInterfaceOrientation.portrait {
            numberOfCellInRow = 4.0
            collectionCellPadding = 10.0
            collectionCellSpacing = 4.0
        }
        
        collectionCellWidth = (view.frame.width / numberOfCellInRow) - collectionCellPadding
        collectionCellHeight = collectionCellWidth
                
        flowLayout.itemSize = CGSize(width: collectionCellWidth, height: collectionCellHeight)
        flowLayout.minimumInteritemSpacing = collectionCellSpacing
        flowLayout.minimumLineSpacing = collectionCellSpacing
        
        return CGSize(
            width  : collectionCellWidth,
            height : collectionCellHeight
        )
    }
    
    func collectionView(
       _ collectionView: UICollectionView,
         didSelectItemAt indexPath: IndexPath) {
    
        let selectedCell = collectionView.cellForItem(at: indexPath) as! FlickrCell
        var cellObjectToUpdate = self.appDelegate.photoQueue[indexPath.row]
            cellObjectToUpdate._imageCellSelected = !cellObjectToUpdate._imageCellSelected!
        
        selectedCell.imageView.image = getCellImageForPhoto(cellObjectToUpdate)
        var dbgStatus = "deselected"
        if  cellObjectToUpdate._imageCellSelected! {
            dbgStatus = "selected"
            
            addCellIndexToSelection(indexPath)
            
        } else {
            
            removeCellIndexFromSelection(indexPath)
        };  setupUIReloadButton()
        
        if appDebugMode {
            print ("photo [\(cellObjectToUpdate._imageSourceURL!)] selected at position \(indexPath.row), status=\(dbgStatus)")
        }
        
        self.appDelegate.photoQueue[indexPath.row] = cellObjectToUpdate
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
        
        if  selectedIndexes.count > 0 &&
            selectedIndexes.count < appDelegate.pinMaxNumberOfPhotos {
            
            callPhotoManagementBySelection()
            
        } else {
       
            callPhotoManagementByPin()
        }
    }
}

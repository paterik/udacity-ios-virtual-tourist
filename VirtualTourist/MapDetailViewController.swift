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
    let cellPhotoImageAlphaForSelected: CGFloat = 0.5
    
    var selectedIndexes = [IndexPath]()
    
    //
    // MARK: Class Variables
    //
    
    var pin: Pin!
    
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
        
        if  photoQueueItem._metaDownloadCompleted == false
            || (photoQueueItem._imageJPEGRaw == nil && photoQueueItem._imageJPEGConverted == nil) {
        
            cell.imageView.image = UIImage(named: "imgPhotoPlaceholder_v1")
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
        }
        
        setupUIReloadButton()
        
        if appDebugMode == true {
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
    
    func replacePhotosOfCollectionFromSelection() {
    
        for (_, indexPath) in selectedIndexes.enumerated() {
            print ("=> replace index \(indexPath.row) from stack")
            
            let updatedCell = photoCollectionView.cellForItem(at: indexPath) as! FlickrCell
            var cellObjectToUpdate = self.appDelegate.photoQueue[indexPath.row]
                cellObjectToUpdate._metaDownloadCompleted = false

            updatedCell.imageView.image = getCellImageForPhoto(cellObjectToUpdate)
            updatedCell.activityIndicator.startAnimating()
            updatedCell.activityIndicator.isHidden = false
            
            self.appDelegate.photoQueue[indexPath.row] = cellObjectToUpdate
        }
        
        toggleRefreshCollectionButton(true)
        refreshCollectionView()
    }
    
    func deletePhotosOfCollectionBySelection() {
        
        for (_, indexPath) in selectedIndexes.enumerated() {
            
            let updatedCell = photoCollectionView.cellForItem(at: indexPath) as! FlickrCell
            var cellObjectToUpdate = self.appDelegate.photoQueue[indexPath.row]
                cellObjectToUpdate._metaDownloadCompleted = false
                appDelegate.photoQueue[indexPath.row] = cellObjectToUpdate
            
            updatedCell.imageView.image = getCellImageForPhoto(cellObjectToUpdate)
            updatedCell.activityIndicator.startAnimating()
            updatedCell.activityIndicator.isHidden = false
            
            print ("=> delete index \(indexPath.row) from stack using metaHash \(cellObjectToUpdate._metaHash!), count=\(self.appDelegate.photoQueue.count)")
            self.deletePhotosOfCollectionByMetaHash(cellObjectToUpdate._metaHash!) {
                
                (success, error) in
                
                // delete successfully done?
                if error == nil {
                    
                    self.appDelegate.photoQueue.remove(at: indexPath.row)
                    self.removeCellIndexFromSelection(indexPath)
                    self.loadPhotosForCollectionView(nil)
                    self.refreshCollectionView()
                
                }
            }
        }
        
        toggleRefreshCollectionButton(true)
        
    }
    
    func resetSelectionForCollectionView() {
    
        for (_, indexPath) in selectedIndexes.enumerated() {
            print ("=> reset index \(indexPath.row) from stack")
            removeCellIndexFromSelection(indexPath)
            
            let updatedCell = photoCollectionView.cellForItem(at: indexPath) as! FlickrCell
            var cellObjectToUpdate = self.appDelegate.photoQueue[indexPath.row]
                cellObjectToUpdate._metaDownloadCompleted = true
                cellObjectToUpdate._imageCellSelected = false
            
            updatedCell.imageView.image = getCellImageForPhoto(cellObjectToUpdate)
            updatedCell.activityIndicator.stopAnimating()
            updatedCell.activityIndicator.isHidden = true
            
            appDelegate.photoQueue[indexPath.row] = cellObjectToUpdate
        }
        
        toggleRefreshCollectionButton(true)
    }
    
    @IBAction func btnReloadPhotoCollection(_ sender: Any) {
        
        // deactivate reload collection button after action call
        toggleRefreshCollectionButton(false)
        
        if selectedIndexes.count > 0 && selectedIndexes.count < appDelegate.pinMaxNumberOfPhotos {
            
            var _title: String   = "Replace \(selectedIndexes.count) Photos"
            var _message: String = "Do you want to replace the \(selectedIndexes.count) photos by new ones or just delete them?"
            var _btnTitleDelete: String = "DELETE \(selectedIndexes.count) photos"
            var _btnTitleReplace: String = "Replace \(selectedIndexes.count) photos"
            
            if selectedIndexes.count == 1 {
                _title = "Replace this Photo"
                _message = "Do you want to replace this photo by new one or just delete it?"
                _btnTitleDelete = "DELETE this photo"
                _btnTitleReplace = "REPLACE this photo"
            }
            
            let alert = UIAlertController(
                title: _title,
                message: _message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "No, Cancel!", style: .default, handler: { (action: UIAlertAction) in
                self.resetSelectionForCollectionView()
            }))
            
            alert.addAction(UIAlertAction(title: _btnTitleReplace, style: .default, handler: { (action: UIAlertAction) in
                self.replacePhotosOfCollectionFromSelection()
            }))
            
            alert.addAction(UIAlertAction(title: _btnTitleDelete, style: .default, handler: { (action: UIAlertAction) in
                self.deletePhotosOfCollectionBySelection()
            }))
            
            present(alert, animated: true, completion: nil)
            
        } else {
        
            let alert = UIAlertController(
                title: "Delete Collection",
                message: "Do you really want to refresh this collection by loading new images?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "No, Cancel!", style: .default, handler: { (action: UIAlertAction) in
                self.toggleRefreshCollectionButton(true)
            }))
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
                
                self.deletePhotosOfCollectionByPin(self.pin) {
                    
                    (success, error) in
                    
                    // delete successfully done?
                    if error == nil {
                        
                        // clean collection view cache and load preset images
                        self.cleanUpCollectionCache()
                        
                        // load new imageSet using flickr api call
                        self.flickrClient.getImagesByMapPin (self.pin!, nil) {
                            
                            (success, error) in
                            
                            if success == false || error != nil {
                                
                                self._handleErrorAsSimpleDialog("Error", error?.description ?? "unkown error occurred")
                            }
                        }
                    }
                }
            }))
            
            present(alert, animated: true, completion: nil)
        }
    }
}

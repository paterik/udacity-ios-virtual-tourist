//
//  MapRegion.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 25.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import CoreData
import MapKit

@objc
class MapRegion: NSManagedObject, MKAnnotation {
    
    @NSManaged var centerLatitude: Double
    @NSManaged var centerLongitude: Double
    @NSManaged var spanLatitude: Double
    @NSManaged var spanLongitude: Double

    var coordinate: CLLocationCoordinate2D {
        
        set {
            
            self.centerLatitude = newValue.latitude
            self.centerLongitude = newValue.longitude
        }
        
        get {
            return CLLocationCoordinate2DMake(
                self.centerLatitude,
                self.centerLongitude
            )
        }
    }
    
    var region: MKCoordinateRegion {
        
        set {
            centerLatitude = newValue.center.latitude
            centerLongitude = newValue.center.longitude
            spanLatitude = newValue.span.latitudeDelta
            spanLongitude = newValue.span.longitudeDelta
        }
        
        get {
            let center = CLLocationCoordinate2DMake(centerLatitude, centerLongitude)
            let span = MKCoordinateSpanMake(spanLatitude, spanLongitude)
            return MKCoordinateRegionMake(center, span)
        }
    }
}

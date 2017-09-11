//
//  FlickrCell.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 10.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit

class FlickrCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        if imageView.image == nil {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        }
    }
}

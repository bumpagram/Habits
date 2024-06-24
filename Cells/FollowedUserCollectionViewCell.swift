//  FollowedUserCollectionViewCell.swift
//  Habits
//  Created by bumpagram on 20/6/24.

import UIKit

class FollowedUserCollectionViewCell: UICollectionViewCell {
    @IBOutlet var primaryTextLabel: UILabel!
    @IBOutlet var secondaryTextLabel: UILabel!
    @IBOutlet var separatorLine: UIView!
    @IBOutlet var separatorLineHeightConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        /*
         awakeFromNib() is a method on NSObject—the base class of all UIKit components—and is called on every object that's created when a storyboard instantiates a scene. Use the awakeFromNib() method to correctly set the line height based on the current traits.
         */
        separatorLineHeightConstraint.constant = 1 / UITraitCollection.current.displayScale
        
    }
    
    
}

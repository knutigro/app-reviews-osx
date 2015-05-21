//
//  ReviewSplitViewController.swift
//  App Reviews
//
//  Created by Knut Inge Grosland on 2015-04-22.
//  Copyright (c) 2015 Cocmoc. All rights reserved.
//

import AppKit

class ReviewSplitViewController : NSSplitViewController {
    
    var application : Application? {
        didSet {
            self.reviewMenuViewController?.application = self.application
            self.reviewViewController?.application = self.application
        }
    }
    
    var reviewMenuViewController : ReviewMenuViewController?
    var reviewViewController : ReviewViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let reviewMenuViewController = self.splitViewItems[0].viewController as? ReviewMenuViewController {
            self.reviewMenuViewController = reviewMenuViewController
            self.reviewMenuViewController?.application = application
        }
        if let reviewViewController = self.splitViewItems[1].viewController as? ReviewViewController {
            self.reviewViewController = reviewViewController
            self.reviewViewController?.application = application
        }
    }
}
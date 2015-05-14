//
//  ReviewMenuViewController.swift
//  App Reviews
//
//  Created by Knut Inge Grosland on 2015-04-22.
//  Copyright (c) 2015 Cocmoc. All rights reserved.
//

import AppKit
import EDStarRating

enum UpdateLabelState {
    case LastUpdate
    case NextUpdate
}

class ReviewMenuViewController: NSViewController {
    
    var managedObjectContext : NSManagedObjectContext!
    let dateFormatter = NSDateFormatter()
    var updateLabelState = UpdateLabelState.LastUpdate {
        didSet {
            self.dateFormatter.dateStyle = .LongStyle
            self.dateFormatter.timeStyle = .MediumStyle
            switch self.updateLabelState {
            case .LastUpdate:
                let updatedAt = self.application?.settings.reviewsUpdatedAt != nil ? dateFormatter.stringFromDate(self.application!.settings.reviewsUpdatedAt!) : ""
                self.reviewsUpdatedAtLabel.stringValue = NSLocalizedString("Updated: ", comment: "review.menu.reviewUpdated") + updatedAt
            case .NextUpdate:
                let nextUpdate = self.application?.settings.nextUpdateAt != nil ? dateFormatter.stringFromDate(self.application!.settings.nextUpdateAt!) : ""
                self.reviewsUpdatedAtLabel.stringValue = NSLocalizedString("Next: ", comment: "review.menu.reviewNextUpdate") + nextUpdate
            }
        }
    }

    @IBOutlet weak var currentVersionStarRating: EDStarRating?
    @IBOutlet weak var allVersionsStarRating: EDStarRating?
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var sellerNameLabel: NSTextField!
    @IBOutlet weak var categoryLabel: NSTextField!
    @IBOutlet weak var updatedAtLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var sizeLabel: NSTextField!

    @IBOutlet weak var averageRatingCurrentLabel: NSTextField!
    @IBOutlet weak var numberOfRatingsCurrentLabel: NSTextField!
    @IBOutlet weak var averageRatingAllLabel: NSTextField!
    @IBOutlet weak var numberOfRatingsAllLabel: NSTextField!
    @IBOutlet weak var reviewsUpdatedAtLabel: NSTextField!

    @IBOutlet weak var localTotalRatingsLabel: NSTextField!

    var pieChartController: ReviewPieChartController?

    var application : Application? {
        didSet {
            self.updateApplicationInfo()
        }
    }

    // MARK: - Init & teardown
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.managedObjectContext = ReviewManager.managedObjectContext()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.application != nil {
            self.updateApplicationInfo()
        }
        
        if let starRating = self.currentVersionStarRating {
            starRating.starImage = NSImage(named: "star")
            starRating.starHighlightedImage = NSImage(named: "star-highlighted")
            starRating.maxRating = 5
            starRating.horizontalMargin = 5
            starRating.displayMode = UInt(EDStarRatingDisplayAccurate)
            starRating.rating = 3.5
        }

        if let starRating = self.allVersionsStarRating {
            starRating.starImage = NSImage(named: "star")
            starRating.starHighlightedImage = NSImage(named: "star-highlighted")
            starRating.maxRating = 5
            starRating.horizontalMargin = 5
            starRating.displayMode = UInt(EDStarRatingDisplayAccurate)
            starRating.rating = 3.5
        }
        
        let applicationMonitor = NSNotificationCenter.defaultCenter().addObserverForName(kDidUpdateApplicationNotification, object: nil, queue: nil) {  [weak self] notification in
            if let strongSelf = self {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    strongSelf.updateApplicationInfo()
                })
            }
        }
        
        let applicationSettingsMonitor = NSNotificationCenter.defaultCenter().addObserverForName(kDidUpdateApplicationSettingsNotification, object: nil, queue: nil) {  [weak self] notification in
            if let strongSelf = self {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    strongSelf.updateApplicationInfo()
                })
            }
        }
    }
    
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationController as? ReviewPieChartController {
            self.pieChartController = controller
        }
    }
    // MARK: - UI
    
    func updateApplicationInfo() {

        let number = (self.application?.averageUserRatingForCurrentVersion ?? "")
        var fileSize = NSString(format: "%.01f", self.application?.fileSizeMb ?? 0) as String
        let averageUserRatingForCurrentVersion = self.application?.averageUserRatingForCurrentVersion.floatValue ?? 0
        var averageUserRatingForCurrentVersionString = ""
        if averageUserRatingForCurrentVersion > 0 {
            averageUserRatingForCurrentVersionString = (NSString(format: "%.1f", averageUserRatingForCurrentVersion) as String)
        }
        self.currentVersionStarRating?.rating = averageUserRatingForCurrentVersion
        
        let numberUserRatingForCurrentVersion = self.application?.userRatingCountForCurrentVersion.integerValue ?? 0

        let averageUserRating = self.application?.averageUserRating.floatValue ?? 0
        var averageUserRatingString = ""
        if averageUserRating > 0 {
            averageUserRatingString = (NSString(format: "%.1f", averageUserRating) as String)
        }
        self.allVersionsStarRating?.rating = averageUserRating

        let userRatingCount = self.application?.userRatingCount.integerValue ?? 0

        self.titleLabel.stringValue = self.application?.trackName ?? ""
        self.sellerNameLabel.stringValue =  NSLocalizedString("By: ", comment: "review.menu.by") + (self.application?.sellerName ?? "")
        self.categoryLabel.stringValue =   NSLocalizedString("Category: ", comment: "review.menu.category") + (self.application?.primaryGenreName ?? "")

        self.dateFormatter.dateStyle = .LongStyle
        self.dateFormatter.timeStyle = .NoStyle
        let releasedAt = self.application?.releaseDate != nil ? dateFormatter.stringFromDate(self.application!.releaseDate!) : ""
        self.updatedAtLabel.stringValue =  NSLocalizedString("Updated: ", comment: "review.menu.updated") + releasedAt
        self.versionLabel.stringValue =   NSLocalizedString("Version: ", comment: "review.menu.version") + (self.application?.version ?? "")
        self.sizeLabel.stringValue =   NSLocalizedString("Size: ", comment: "review.menu.size") + fileSize + " Mb"
        
        self.averageRatingCurrentLabel.stringValue =   NSLocalizedString("Average rating: ", comment: "review.menu.currentAverageRating") + averageUserRatingForCurrentVersionString

        self.numberOfRatingsCurrentLabel.stringValue =   NSLocalizedString("Number of ratings: ", comment: "review.menu.currentAverageRating") + (NSString(format: "%i", numberUserRatingForCurrentVersion) as String)

        self.averageRatingAllLabel.stringValue =   NSLocalizedString("Average rating: ", comment: "review.menu.currentAverageRating") + averageUserRatingString
        
        self.numberOfRatingsAllLabel.stringValue =   NSLocalizedString("Number of ratings: ", comment: "review.menu.currentAverageRating") + (NSString(format: "%i", userRatingCount) as String)
        
        self.updateLabelState = .LastUpdate
        
        if let application = self.application {
            let reviews = DatabaseHandler.numberOfReviewsForApplication(application.objectID, rating: nil, context: ReviewManager.managedObjectContext())
            self.pieChartController?.slices = [Float(reviews.0), Float(reviews.1), Float(reviews.2), Float(reviews.3), Float(reviews.4)]
            self.pieChartController?.pieChart?.reloadData()
            let total = reviews.0 + reviews.1 + reviews.2 + reviews.3 + reviews.4
            self.localTotalRatingsLabel.stringValue = NSLocalizedString("Total: ", comment: "review.menu.localRatingCount") + (NSString(format: "%i", total) as String)
        }

        
    }
    
    @IBAction func toogleUpdateLabel(objects:AnyObject?) {
        if (self.updateLabelState == .LastUpdate) {
            self.updateLabelState = .NextUpdate
        } else {
            self.updateLabelState = .LastUpdate
        }
    }
}


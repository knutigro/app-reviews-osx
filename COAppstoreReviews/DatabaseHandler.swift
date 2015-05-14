//
//  COImportController.swift
//  App Reviews
//
//  Created by Knut Inge Grosland on 2015-04-09.
//  Copyright (c) 2015 Cocmoc. All rights reserved.
//

import Foundation
import AppKit
import SwiftyJSON

class DatabaseHandler {
    
    typealias CompletionBlock = () -> ()
    
    // MARK: - Applications handling

    class func saveApplication(applicationJSON : JSON) {
        DatabaseHandler.saveDataInContext({ (context) -> Void in
            
            if applicationJSON.isApplicationEntity, let apID = applicationJSON.trackId {
                if let application = Application.getWithAppId(apID, context: context) {
                    application.updatedAt = NSDate()
                    application.updateWithJSON(applicationJSON)
                } else {
                    let application = Application.new(apID, context: context)
                    application.updateWithJSON(applicationJSON)
                }
            }
        })
    }
    
    class func removeApplication(objectId : NSManagedObjectID) {
        DatabaseHandler.saveDataInContext({ (context) -> Void in
            var error : NSError?
            if let application = context.existingObjectWithID(objectId, error: &error) {
                context.deleteObject(application)
            }
        })
    }
    
    class func resetNewReviewsCountForApplication(objectId : NSManagedObjectID) {
        DatabaseHandler.saveDataInContext({ (context) -> Void in
            var error : NSError?
            if let application = context.existingObjectWithID(objectId, error: &error) as? Application {
                application.settings.resetNewReviews()
            }
        })
    }

    class func allApplications(context: NSManagedObjectContext) -> [Application]? {
        
        let fetchRequest = NSFetchRequest(entityName: kEntityNameApplication)
        var error : NSError?
        let result = context.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            println(error)
        }
        
        return result as? [Application]
    }
    
    class func numberOfReviewsForApplication(objectId : NSManagedObjectID, rating: Int?, context: NSManagedObjectContext) -> (Int, Int, Int, Int, Int) {
        var error : NSError?
        var one = 0, two = 0, three = 0, four = 0, five = 0

        if let application = context.existingObjectWithID(objectId, error: &error) as? Application {
            var fetchRequest = NSFetchRequest(entityName: kEntityNameReview)
            
            fetchRequest.predicate = NSPredicate(format: "application = %@ AND rating == 1", application)
            one = context.countForFetchRequest(fetchRequest, error: &error)

            fetchRequest.predicate = NSPredicate(format: "application = %@ AND rating == 2", application)
            two = context.countForFetchRequest(fetchRequest, error: &error)

            fetchRequest.predicate = NSPredicate(format: "application = %@ AND rating == 3", application)
            three = context.countForFetchRequest(fetchRequest, error: &error)

            fetchRequest.predicate = NSPredicate(format: "application = %@ AND rating == 4", application)
            four = context.countForFetchRequest(fetchRequest, error: &error)

            fetchRequest.predicate = NSPredicate(format: "application = %@ AND rating == 5", application)
            five = context.countForFetchRequest(fetchRequest, error: &error)

            if error != nil { println(error) }
        }
        
        return (one, two, three, four, five)
    }
    
    class func saveReviews(reviews : [JSON], applactionObjectId objectId : NSManagedObjectID) {
        DatabaseHandler.saveDataInContext({ (context) -> Void in
            
            var error : NSError?
            
            if let application = context.existingObjectWithID(objectId, error: &error) as? Application {
                
                if error != nil {
                    println(error)
                }
                
                var updatedReviews = [Review]()
                
                for var index = 0; index < reviews.count; index++ {
                    let entry = reviews[index]
                    
                    if entry.isReviewEntity, let apID = entry.reviewApID {
                        var review : Review!
                        
                        if let newReview = Review.get(apID, context: context) {
                            // Review allready exist in database
                            review = newReview
                        } else {
                            // create new review
                            review = Review.new(apID, context: context)
                            application.settings.increaseNewReviews()
                        }
                        
                        review.updateWithJSON(entry)
                        review.country = ""
                        review.updatedAt = NSDate()
                        var reviews = application.mutableSetValueForKey("reviews")
                        reviews.addObject(review)
                        review.application = application
                        updatedReviews.append(review)
                    }
                }
                application.settings.updatedAt = NSDate()
                application.settings.reviewsUpdatedAt = NSDate()
                application.settings.nextUpdateAt = NSDate().dateByAddingTimeInterval(kDefaultReviewUpdateInterval)
            }
        })
    }

    // MARK: - DB Handling

    class func saveDataInContext(saveBlock: (context: NSManagedObjectContext) -> Void)  {
        DatabaseHandler.saveDataInContext(saveBlock, completion: nil)
    }

    class func saveDataInContext(saveBlock: (context: NSManagedObjectContext) -> Void, completion: CompletionBlock?)  {

        var context = ReviewManager.backgroundObjectContext()
        
        context.performBlock { () -> Void in
            saveBlock(context: context)
            
            if context.hasChanges {
                var error : NSError? = nil
                context.save(&error)
                if error != nil { println("error: " + error!.localizedDescription) }
            }

            if let completion = completion {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion()
                })
            }
        }
    }
    



}

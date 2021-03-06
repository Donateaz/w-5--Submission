//
//  AppDelegate.swift
//  Twitter
//
//  Created by Donatea Zefi on 3/01/16
//  Copyright © 2016 Donatea. All rights reserved.
//

import UIKit
import BDBOAuth1Manager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?;
    var splashInterludePersist = false;
    
    var tabBarController: UITabBarController?;
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
//        UIApplication.sharedApplication().statusBarStyle = .LightContent;
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        NSNotificationCenter.defaultCenter().postNotificationName("ReturnToSplash", object: nil);
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        
        TwitterClient.sharedInstance.handleOpenUrl(url);
        
        return true;
    }
    
    func switchToProfileTab(reloadUserProfile: Bool = false) {
        if(reloadUserProfile) {
            delay(1.0, closure: { () -> () in
                let pnVc = self.tabBarController?.childViewControllers.last as! UINavigationController;
                let pVc = pnVc.viewControllers.first as! ProfileViewController;
                pVc.reloadData();
            });
        }
        
        if tabBarController != nil {
            if(tabBarController!.selectedIndex != 3) {
                tabBarController!.selectedIndex = 3
            }
        }
    }
    
    func openTweetDetails(tweet: Tweet) {
    let storyboard = UIStoryboard(name: "Main", bundle:nil);
    let vc = storyboard.instantiateViewControllerWithIdentifier("DetailsViewController") as! DetailsViewController;
    vc.tweet = tweet;
    self.window?.rootViewController!.presentedViewController!.presentViewController(vc, animated:true, completion:nil);
}
}


extension String
{
    func replace(target: String, withString: String) -> String
    {
        return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}


func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
    
    
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
        //
    });
    
    dispatch_async(dispatch_get_main_queue()) { () -> Void in
        //
    }
    
}
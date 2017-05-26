//
//  AppDelegate.swift
//  CardsAgainst
//
//  Created by JP Simard on 10/25/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    
    var isViewerSide = false
    
    var isViewerLandscapeUpdate = false
    
    var strscrollPosition = "right"
    
    var vsideAnimationEnable = false
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Simultaneously advertise and browse for other device
        ConnectionManager.start()
        return true
    }
    class func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        if self.isViewerSide && !self.isViewerLandscapeUpdate {
            return UIInterfaceOrientationMask.portrait
        }
        else {
            return UIInterfaceOrientationMask.portrait
        }
    }
}

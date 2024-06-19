//  AppDelegate.swift
//  Habits
//  Created by bumpagram on 7/6/24

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // “you'll increase the cache size so that repeated image requests don't require sending data over the network each time”   УВЕЛИЧИМ КЭШ ДЛЯ КАРТИНОК до выполнения запроса в сеть
        let tempDir = NSTemporaryDirectory() // returns path for temp directory for current user
        let urlCache = URLCache(memoryCapacity: 25_000_000, diskCapacity: 50_000_000, diskPath: tempDir)
        URLCache.shared = urlCache
        
        return true
    }
    
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


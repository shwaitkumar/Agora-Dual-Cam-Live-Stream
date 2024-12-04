//
//  AppEntryPoint.swift
//  Agora Dual Cam Live Stream
//
//  Created by Shwait Kumar on 04/12/24.
//

import UIKit

@main
class AppEntryPoint: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Create a new UIWindow and set the root view controller
        window = UIWindow(frame: UIScreen.main.bounds)
        let rootVC = RoleSelectionViewController() // Replace with your starting view controller
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()

        return true
    }
}

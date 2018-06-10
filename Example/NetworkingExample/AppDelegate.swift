//
//  AppDelegate.swift
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Public Variables
    public var window: UIWindow?
    
    
    
    // MARK: - App Delegate Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        self.validateConfiguration()

        // Setup Initial UI
        self.initializeUI()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {}
    
    func applicationDidEnterBackground(_ application: UIApplication) {}
    
    func applicationWillEnterForeground(_ application: UIApplication) {}
    
    func applicationDidBecomeActive(_ application: UIApplication) {}
    
    func applicationWillTerminate(_ application: UIApplication) {}
    
    
    
    // MARK: - Helper Functions
    func initializeUI() {
        let vc = ViewController()
        
        let nvc = UINavigationController(rootViewController: vc)
        nvc.navigationBar.barStyle = .blackTranslucent
        nvc.setNavigationBarHidden(true, animated: false)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = nvc
        self.window?.makeKeyAndVisible()
    }
    
    func validateConfiguration() {
        if let path = Bundle.main.path(forResource: "Config", ofType: "json") {
            do {
                // If able to parse the Config.json file then continue
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            } catch {
                // Else prevent developer from running the app
                print("DEVELOPER WARNING: Please include a valid Config.json file.")
                fatalError()
            }
        }
    }
}


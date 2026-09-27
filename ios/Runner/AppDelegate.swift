
import Flutter
import GoogleMaps
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    guard let mapsApiKey = Bundle.main.object(
      forInfoDictionaryKey: "GMSApiKey"
    ) as? String,
    !mapsApiKey.isEmpty,
    !mapsApiKey.contains("$(") else {
      fatalError("Google Maps API key is missing from Info.plist")
    }

    GMSServices.provideAPIKey(mapsApiKey)

    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }
}